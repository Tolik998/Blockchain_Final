// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ShieldAMM
 * @notice Constant-product AMM (x·y = k) built from scratch for the ShieldFi protocol.
 *
 * Features:
 *  - 0.3% swap fee (30 bps), retained in the pool and accrues to LPs
 *  - Slippage protection via `minAmountOut` parameter on swaps
 *  - LP tokens (ERC-20) representing pro-rata share of the pool
 *  - Minimum liquidity lock (1000 wei) to prevent dust attacks
 *  - ReentrancyGuard on all state-changing functions
 *  - Checks-Effects-Interactions pattern throughout
 *
 * Design patterns:
 *  - CEI (Checks-Effects-Interactions)
 *  - ReentrancyGuard
 *  - Pull-over-push (users call functions to withdraw)
 *
 * @dev This is an educational implementation. Do NOT use in production without a
 *      professional audit and additional safety mechanisms (TWAP, flash-loan guard).
 */
contract ShieldAMM is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Constants ──────────────────────────────────────────────────────────────
    uint256 public constant FEE_BPS = 30;           // 0.30 %
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant MINIMUM_LIQUIDITY = 1_000; // locked forever on first add

    // ── Immutables ─────────────────────────────────────────────────────────────
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // ── State ──────────────────────────────────────────────────────────────────
    uint112 private _reserve0;
    uint112 private _reserve1;

    // ── Errors ─────────────────────────────────────────────────────────────────
    error ZeroAddress();
    error SameToken();
    error ZeroAmount();
    error InsufficientLiquidity();
    error InsufficientInputAmount();
    error InsufficientOutputAmount();
    error SlippageExceeded();
    error InvalidToken();
    error KInvariantViolated();

    // ── Events ─────────────────────────────────────────────────────────────────
    /// @notice Emitted when liquidity is added to the pool.
    event LiquidityAdded(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 lpMinted
    );

    /// @notice Emitted when liquidity is removed from the pool.
    event LiquidityRemoved(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 lpBurned
    );

    /// @notice Emitted on every swap.
    event Swap(
        address indexed sender,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );

    /// @notice Emitted when reserves change.
    event Sync(uint112 reserve0, uint112 reserve1);

    // ── Constructor ────────────────────────────────────────────────────────────

    /**
     * @param tokenA  Address of the first token (order is normalized by address).
     * @param tokenB  Address of the second token.
     */
    constructor(address tokenA, address tokenB) ERC20("ShieldAMM LP", "SHIELD-LP") {
        if (tokenA == address(0) || tokenB == address(0)) revert ZeroAddress();
        if (tokenA == tokenB) revert SameToken();
        // Normalize order so token0 < token1 (standard AMM convention)
        (token0, token1) = tokenA < tokenB
            ? (IERC20(tokenA), IERC20(tokenB))
            : (IERC20(tokenB), IERC20(tokenA));
    }

    // ── View helpers ───────────────────────────────────────────────────────────

    /// @notice Returns current reserves of token0 and token1.
    function getReserves() public view returns (uint112 reserve0, uint112 reserve1) {
        return (_reserve0, _reserve1);
    }

    /**
     * @notice Compute the output amount for a given input, applying 0.3% fee.
     * @param amountIn   Exact input amount (before fee).
     * @param reserveIn  Reserve of the input token.
     * @param reserveOut Reserve of the output token.
     * @return amountOut Output amount after fee.
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        if (amountIn == 0) revert InsufficientInputAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        // amountInWithFee = amountIn * (10000 - 30) = amountIn * 9970
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_BPS);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @notice Compute the required input amount to receive an exact output.
     * @param amountOut  Desired output amount.
     * @param reserveIn  Reserve of the input token.
     * @param reserveOut Reserve of the output token.
     * @return amountIn  Required input amount (inclusive of fee).
     */
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountIn) {
        if (amountOut == 0) revert InsufficientOutputAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();
        uint256 numerator = reserveIn * amountOut * FEE_DENOMINATOR;
        uint256 denominator = (reserveOut - amountOut) * (FEE_DENOMINATOR - FEE_BPS);
        amountIn = numerator / denominator + 1;
    }

    // ── Liquidity ──────────────────────────────────────────────────────────────

    /**
     * @notice Add liquidity to the pool and receive LP tokens.
     * @param amount0Desired  Desired amount of token0 to deposit.
     * @param amount1Desired  Desired amount of token1 to deposit.
     * @param amount0Min      Minimum token0 accepted (slippage guard).
     * @param amount1Min      Minimum token1 accepted (slippage guard).
     * @param to              Recipient of LP tokens.
     * @return amount0        Actual token0 deposited.
     * @return amount1        Actual token1 deposited.
     * @return liquidity      LP tokens minted.
     */
    function addLiquidity(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1, uint256 liquidity) {
        // ── Checks ────────────────────────────────────────────────────────────
        if (to == address(0)) revert ZeroAddress();
        if (amount0Desired == 0 || amount1Desired == 0) revert ZeroAmount();

        (uint112 res0, uint112 res1) = getReserves();

        if (res0 == 0 && res1 == 0) {
            // First liquidity provision — accept desired amounts as-is
            amount0 = amount0Desired;
            amount1 = amount1Desired;
        } else {
            // Maintain current ratio
            uint256 amount1Optimal = (amount0Desired * res1) / res0;
            if (amount1Optimal <= amount1Desired) {
                if (amount1Optimal < amount1Min) revert SlippageExceeded();
                amount0 = amount0Desired;
                amount1 = amount1Optimal;
            } else {
                uint256 amount0Optimal = (amount1Desired * res0) / res1;
                if (amount0Optimal < amount0Min) revert SlippageExceeded();
                amount0 = amount0Optimal;
                amount1 = amount1Desired;
            }
        }

        // ── Effects ───────────────────────────────────────────────────────────
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) {
            // Geometric mean minus MINIMUM_LIQUIDITY locked in contract
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            // Mint MINIMUM_LIQUIDITY to address(1) to lock it permanently
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply_) / res0,
                (amount1 * totalSupply_) / res1
            );
        }
        if (liquidity == 0) revert InsufficientLiquidity();
        _mint(to, liquidity);
        _updateReserves(uint112(res0 + amount0), uint112(res1 + amount1));

        // ── Interactions ──────────────────────────────────────────────────────
        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        emit LiquidityAdded(to, amount0, amount1, liquidity);
    }

    /**
     * @notice Remove liquidity from the pool by burning LP tokens.
     * @param liquidity   Amount of LP tokens to burn.
     * @param amount0Min  Minimum token0 to receive (slippage guard).
     * @param amount1Min  Minimum token1 to receive (slippage guard).
     * @param to          Recipient of the underlying tokens.
     * @return amount0    Token0 returned.
     * @return amount1    Token1 returned.
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        // ── Checks ────────────────────────────────────────────────────────────
        if (to == address(0)) revert ZeroAddress();
        if (liquidity == 0) revert ZeroAmount();

        (uint112 res0, uint112 res1) = getReserves();
        uint256 totalSupply_ = totalSupply();

        amount0 = (liquidity * res0) / totalSupply_;
        amount1 = (liquidity * res1) / totalSupply_;

        if (amount0 < amount0Min || amount1 < amount1Min) revert SlippageExceeded();
        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidity();

        // ── Effects ───────────────────────────────────────────────────────────
        _burn(msg.sender, liquidity);
        _updateReserves(uint112(res0 - amount0), uint112(res1 - amount1));

        // ── Interactions ──────────────────────────────────────────────────────
        token0.safeTransfer(to, amount0);
        token1.safeTransfer(to, amount1);

        emit LiquidityRemoved(to, amount0, amount1, liquidity);
    }

    // ── Swap ───────────────────────────────────────────────────────────────────

    /**
     * @notice Swap an exact amount of `tokenIn` for at least `minAmountOut` of the other token.
     * @param tokenIn     Address of the input token (must be token0 or token1).
     * @param amountIn    Amount of input token to swap.
     * @param minAmountOut Minimum output amount required (slippage protection).
     * @param to          Recipient of output tokens.
     * @return amountOut  Actual output amount.
     */
    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        address to
    ) external nonReentrant returns (uint256 amountOut) {
        // ── Checks ────────────────────────────────────────────────────────────
        if (tokenIn != address(token0) && tokenIn != address(token1)) revert InvalidToken();
        if (amountIn == 0) revert ZeroAmount();
        if (to == address(0)) revert ZeroAddress();

        bool isToken0In = tokenIn == address(token0);
        (uint112 res0, uint112 res1) = getReserves();

        (uint256 reserveIn, uint256 reserveOut) = isToken0In
            ? (uint256(res0), uint256(res1))
            : (uint256(res1), uint256(res0));

        amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        if (amountOut < minAmountOut) revert SlippageExceeded();
        if (amountOut == 0) revert InsufficientOutputAmount();

        // ── Effects ───────────────────────────────────────────────────────────
        (uint112 newRes0, uint112 newRes1) = isToken0In
            ? (uint112(res0 + amountIn), uint112(res1 - amountOut))
            : (uint112(res0 - amountOut), uint112(res1 + amountIn));

        // Verify k-invariant: newRes0 * newRes1 >= res0 * res1
        // (inequality because fee stays in pool, increasing k over time)
        if (uint256(newRes0) * uint256(newRes1) < uint256(res0) * uint256(res1)) {
            revert KInvariantViolated();
        }

        _updateReserves(newRes0, newRes1);

        // ── Interactions ──────────────────────────────────────────────────────
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(isToken0In ? address(token1) : address(token0)).safeTransfer(to, amountOut);

        emit Swap(msg.sender, tokenIn, amountIn, amountOut, to);
    }

    // ── Internal ───────────────────────────────────────────────────────────────

    function _updateReserves(uint112 newRes0, uint112 newRes1) internal {
        _reserve0 = newRes0;
        _reserve1 = newRes1;
        emit Sync(newRes0, newRes1);
    }
}
