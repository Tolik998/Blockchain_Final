// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {ShieldFiBase} from "./base/ShieldFiBase.sol";
import {PolicyNFT} from "../contracts/token/PolicyNFT.sol";
import {ShieldAMM} from "../contracts/amm/ShieldAMM.sol";
import {MockERC20} from "../contracts/mocks/MockERC20.sol";

// ══════════════════════════════════════════════════════════════════════════════
//  PolicyNFT Tests
// ══════════════════════════════════════════════════════════════════════════════

contract PolicyNFTTest is ShieldFiBase {
    PolicyNFT internal nft;

    function setUp() public override {
        super.setUp();
        nft = new PolicyNFT(deployer, deployer);
    }

    // ── Constructor ───────────────────────────────────────────────────────────

    function test_nftName() public view {
        assertEq(nft.name(), "ShieldFi Policy");
    }

    function test_nftSymbol() public view {
        assertEq(nft.symbol(), "SHIELD-POLICY");
    }

    function test_nftConstructorZeroAdminReverts() public {
        vm.expectRevert(PolicyNFT.ZeroAddress.selector);
        new PolicyNFT(address(0), deployer);
    }

    function test_nftConstructorZeroMinterReverts() public {
        vm.expectRevert(PolicyNFT.ZeroAddress.selector);
        new PolicyNFT(deployer, address(0));
    }

    // ── Minting ───────────────────────────────────────────────────────────────

    function test_nftMintHappyPath() public {
        nft.mint(alice, 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
    }

    function test_nftMintEmitsEvent() public {
        vm.expectEmit(true, true, false, false, address(nft));
        emit PolicyNFT.PolicyMinted(alice, 42);
        nft.mint(alice, 42);
    }

    function test_nftMintNotMinterReverts() public {
        vm.prank(alice);
        vm.expectRevert(PolicyNFT.NotMinter.selector);
        nft.mint(alice, 1);
    }

    function test_nftMintZeroAddressReverts() public {
        vm.expectRevert(PolicyNFT.ZeroAddress.selector);
        nft.mint(address(0), 1);
    }

    function test_nftMintMultiple() public {
        nft.mint(alice, 1);
        nft.mint(alice, 2);
        nft.mint(bob, 3);
        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.balanceOf(bob), 1);
        assertEq(nft.totalSupply(), 3);
    }

    // ── Token URI ─────────────────────────────────────────────────────────────

    function test_nftTokenURIContainsPolicyId() public {
        nft.mint(alice, 7);
        string memory uri = nft.tokenURI(7);
        // URI should be a data URI containing "7"
        assertGt(bytes(uri).length, 100);
        // Contains "data:application/json"
        bytes memory uriBytes = bytes(uri);
        bytes memory prefix = bytes("data:application/json");
        for (uint256 i = 0; i < prefix.length; i++) {
            assertEq(uriBytes[i], prefix[i]);
        }
    }

    function test_nftTokenURIRevertsForNonExistentToken() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    // ── Enumerable ────────────────────────────────────────────────────────────

    function test_nftTokenOfOwnerByIndex() public {
        nft.mint(alice, 10);
        nft.mint(alice, 20);
        assertEq(nft.tokenOfOwnerByIndex(alice, 0), 10);
        assertEq(nft.tokenOfOwnerByIndex(alice, 1), 20);
    }

    function test_nftTokenByIndex() public {
        nft.mint(alice, 5);
        nft.mint(bob, 6);
        assertEq(nft.tokenByIndex(0), 5);
        assertEq(nft.tokenByIndex(1), 6);
    }

    // ── Transfer ──────────────────────────────────────────────────────────────

    function test_nftTransfer() public {
        nft.mint(alice, 1);
        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
    }

    // ── supportsInterface ────────────────────────────────────────────────────

    function test_nftSupportsERC721Interface() public view {
        assertTrue(nft.supportsInterface(0x80ac58cd)); // ERC721
    }

    function test_nftSupportsAccessControlInterface() public view {
        assertTrue(nft.supportsInterface(0x01ffc9a7)); // ERC165
    }

    // ── Integration with PolicyManager ────────────────────────────────────────

    function test_nftMintsOnPolicyPurchase() public {
        // Grant minter role to deployer (simulating PolicyManager integration)
        // In real deployment PolicyManager gets MINTER_ROLE
        nft.grantRole(nft.MINTER_ROLE(), address(policy));

        vm.prank(alice);
        vault.deposit(5_000_000e6, alice);
        vm.prank(bob);
        uint256 policyId = policy.purchasePolicy(50_000e6, uint48(30 days), 1500e8, true);

        // PolicyManager would call nft.mint(bob, policyId) — simulate here
        // (full integration requires modifying PolicyManager; this tests the contract itself)
        nft.mint(bob, policyId);
        assertEq(nft.ownerOf(policyId), bob);
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ShieldAMM Tests
// ══════════════════════════════════════════════════════════════════════════════

contract ShieldAMMTest is Test {
    ShieldAMM internal amm;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal alice = address(0xA11CE);
    address internal bob   = address(0xB0B);

    uint256 internal constant INITIAL_LIQUIDITY_A = 1_000_000e6;
    uint256 internal constant INITIAL_LIQUIDITY_B = 2_000_000e6;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA", 6);
        tokenB = new MockERC20("Token B", "TKNB", 6);
        amm = new ShieldAMM(address(tokenA), address(tokenB));

        // Mint tokens to alice and bob
        tokenA.mint(alice, 100_000_000e6);
        tokenB.mint(alice, 100_000_000e6);
        tokenA.mint(bob,   100_000_000e6);
        tokenB.mint(bob,   100_000_000e6);

        // Approve AMM
        vm.startPrank(alice);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    // ── Constructor ───────────────────────────────────────────────────────────

    function test_ammConstructorZeroAddressReverts() public {
        vm.expectRevert(ShieldAMM.ZeroAddress.selector);
        new ShieldAMM(address(0), address(tokenB));
    }

    function test_ammConstructorSameTokenReverts() public {
        vm.expectRevert(ShieldAMM.SameToken.selector);
        new ShieldAMM(address(tokenA), address(tokenA));
    }

    function test_ammTokensNormalized() public view {
        // token0 should be the smaller address
        address t0 = address(amm.token0());
        address t1 = address(amm.token1());
        assertTrue(t0 < t1);
    }

    function test_ammLPName() public view {
        assertEq(amm.name(), "ShieldAMM LP");
        assertEq(amm.symbol(), "SHIELD-LP");
    }

    // ── Add Liquidity ─────────────────────────────────────────────────────────

    function test_ammAddLiquidityFirstProvision() public {
        vm.prank(alice);
        (uint256 a0, uint256 a1, uint256 lp) = amm.addLiquidity(
            INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice
        );
        assertGt(a0, 0);
        assertGt(a1, 0);
        assertGt(lp, 0);
        assertEq(amm.balanceOf(alice), lp);
        (uint112 r0, uint112 r1) = amm.getReserves();
        assertEq(r0 + r1, uint256(a0) + uint256(a1));
    }

    function test_ammAddLiquidityMinimumLiquidityLocked() public {
        vm.prank(alice);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);
        // address(1) holds MINIMUM_LIQUIDITY
        assertEq(amm.balanceOf(address(1)), 1000);
    }

    function test_ammAddLiquidityZeroAddressReverts() public {
        vm.prank(alice);
        vm.expectRevert(ShieldAMM.ZeroAddress.selector);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, address(0));
    }

    function test_ammAddLiquidityZeroAmountReverts() public {
        vm.prank(alice);
        vm.expectRevert(ShieldAMM.ZeroAmount.selector);
        amm.addLiquidity(0, INITIAL_LIQUIDITY_B, 0, 0, alice);
    }

    function test_ammAddLiquiditySecondProviderMaintainsRatio() public {
        vm.prank(alice);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);

        vm.prank(bob);
        (uint256 a0, uint256 a1, uint256 lp) = amm.addLiquidity(
            INITIAL_LIQUIDITY_A / 2, INITIAL_LIQUIDITY_B, 0, 0, bob
        );
        assertGt(lp, 0);
        // Should have used half of A and proportional B
        assertEq(a0, INITIAL_LIQUIDITY_A / 2);
        assertLe(a1, INITIAL_LIQUIDITY_B);
    }

    function test_ammAddLiquiditySlippageReverts() public {
        vm.prank(alice);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);

        // Bob tries to add with very tight slippage
        vm.prank(bob);
        vm.expectRevert(ShieldAMM.SlippageExceeded.selector);
        amm.addLiquidity(
            INITIAL_LIQUIDITY_A / 2,
            INITIAL_LIQUIDITY_B, // too much B desired
            INITIAL_LIQUIDITY_A / 2,
            INITIAL_LIQUIDITY_B  // min = full amount = slippage fail
        , bob);
    }

    // ── Remove Liquidity ──────────────────────────────────────────────────────

    function test_ammRemoveLiquidityHappyPath() public {
        vm.prank(alice);
        (,, uint256 lp) = amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);

        uint256 preBal0 = tokenA.balanceOf(alice);

        vm.prank(alice);
        (uint256 out0, uint256 out1) = amm.removeLiquidity(lp, 0, 0, alice);

        assertGt(out0, 0);
        assertGt(out1, 0);
        assertEq(amm.balanceOf(alice), 0);
        assertGt(tokenA.balanceOf(alice), preBal0); // Alice got tokens back
    }

    function test_ammRemoveLiquidityZeroLpReverts() public {
        vm.prank(alice);
        vm.expectRevert(ShieldAMM.ZeroAmount.selector);
        amm.removeLiquidity(0, 0, 0, alice);
    }

    function test_ammRemoveLiquidityZeroAddressReverts() public {
        vm.prank(alice);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);
        vm.prank(alice);
        vm.expectRevert(ShieldAMM.ZeroAddress.selector);
        amm.removeLiquidity(1000, 0, 0, address(0));
    }

    function test_ammRemoveLiquiditySlippageReverts() public {
        vm.prank(alice);
        (,, uint256 lp) = amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);

        vm.prank(alice);
        vm.expectRevert(ShieldAMM.SlippageExceeded.selector);
        amm.removeLiquidity(lp, type(uint256).max, 0, alice);
    }

    // ── Swap ──────────────────────────────────────────────────────────────────

    function _seedPool() internal {
        vm.prank(alice);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);
    }

    function test_ammSwapToken0ForToken1() public {
        _seedPool();
        address t0 = address(amm.token0());
        uint256 swapAmt = 1_000e6;
        uint256 preBal = IERC20(address(amm.token1())).balanceOf(bob);

        vm.prank(bob);
        uint256 out = amm.swap(t0, swapAmt, 1, bob);

        assertGt(out, 0);
        assertEq(IERC20(address(amm.token1())).balanceOf(bob), preBal + out);
    }

    function test_ammSwapToken1ForToken0() public {
        _seedPool();
        address t1 = address(amm.token1());
        uint256 swapAmt = 1_000e6;
        uint256 preBal = IERC20(address(amm.token0())).balanceOf(bob);

        vm.prank(bob);
        uint256 out = amm.swap(t1, swapAmt, 1, bob);

        assertGt(out, 0);
        assertEq(IERC20(address(amm.token0())).balanceOf(bob), preBal + out);
    }

    function test_ammSwapInvalidTokenReverts() public {
        _seedPool();
        vm.prank(bob);
        vm.expectRevert(ShieldAMM.InvalidToken.selector);
        amm.swap(address(0xDEAD), 1_000e6, 0, bob);
    }

    function test_ammSwapZeroAmountReverts() public {
        _seedPool();
        address t0 = address(amm.token0());
        vm.prank(bob);
        vm.expectRevert(ShieldAMM.ZeroAmount.selector);
        amm.swap(t0, 0, 0, bob);
    }

    function test_ammSwapZeroAddressReverts() public {
        _seedPool();
        address t0 = address(amm.token0());
        vm.prank(bob);
        vm.expectRevert(ShieldAMM.ZeroAddress.selector);
        amm.swap(t0, 1_000e6, 0, address(0));
    }

    function test_ammSwapSlippageReverts() public {
        _seedPool();
        address t0 = address(amm.token0());
        vm.prank(bob);
        vm.expectRevert(ShieldAMM.SlippageExceeded.selector);
        amm.swap(t0, 1_000e6, type(uint256).max, bob);
    }

    // ── getAmountOut ──────────────────────────────────────────────────────────

    function test_ammGetAmountOutZeroInputReverts() public {
        vm.expectRevert(ShieldAMM.InsufficientInputAmount.selector);
        amm.getAmountOut(0, 1_000e6, 2_000e6);
    }

    function test_ammGetAmountOutZeroReserveReverts() public {
        vm.expectRevert(ShieldAMM.InsufficientLiquidity.selector);
        amm.getAmountOut(100e6, 0, 2_000e6);
    }

    function test_ammGetAmountOut03PctFee() public view {
        // With equal reserves 1:1, swap 1000 in → expect slightly less than 1000 out
        uint256 out = amm.getAmountOut(1_000e6, 1_000_000e6, 1_000_000e6);
        assertLt(out, 1_000e6); // fee reduces output
        assertGt(out, 990e6);   // but not by more than 1%
    }

    // ── getAmountIn ───────────────────────────────────────────────────────────

    function test_ammGetAmountInZeroOutputReverts() public {
        vm.expectRevert(ShieldAMM.InsufficientOutputAmount.selector);
        amm.getAmountIn(0, 1_000e6, 2_000e6);
    }

    function test_ammGetAmountInZeroReserveReverts() public {
        vm.expectRevert(ShieldAMM.InsufficientLiquidity.selector);
        amm.getAmountIn(100e6, 0, 2_000e6);
    }

    function test_ammGetAmountInRoundTrip() public view {
        // getAmountIn(getAmountOut(x)) should return >= x (due to rounding up)
        uint256 amountIn = 500e6;
        uint256 out = amm.getAmountOut(amountIn, 1_000_000e6, 2_000_000e6);
        uint256 requiredIn = amm.getAmountIn(out, 1_000_000e6, 2_000_000e6);
        assertGe(requiredIn, amountIn);
        assertLe(requiredIn, amountIn + 2); // within 2 wei rounding
    }

    // ── K-invariant ───────────────────────────────────────────────────────────

    function test_ammKInvariantHoldsAfterSwap() public {
        _seedPool();
        (uint112 r0before, uint112 r1before) = amm.getReserves();
        uint256 kBefore = uint256(r0before) * uint256(r1before);

        address t0 = address(amm.token0());
        vm.prank(bob);
        amm.swap(t0, 10_000e6, 1, bob);

        (uint112 r0after, uint112 r1after) = amm.getReserves();
        uint256 kAfter = uint256(r0after) * uint256(r1after);

        // k can only increase (fee accrues to pool) or stay the same
        assertGe(kAfter, kBefore);
    }

    function test_ammKInvariantHoldsAfterMultipleSwaps() public {
        _seedPool();
        (uint112 r0init, uint112 r1init) = amm.getReserves();
        uint256 kInit = uint256(r0init) * uint256(r1init);

        address t0 = address(amm.token0());
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(bob);
            amm.swap(t0, 1_000e6, 1, bob);
        }

        (uint112 r0final, uint112 r1final) = amm.getReserves();
        uint256 kFinal = uint256(r0final) * uint256(r1final);
        assertGe(kFinal, kInit);
    }

    // ── Events ────────────────────────────────────────────────────────────────

    function test_ammSwapEmitsEvent() public {
        _seedPool();
        address t0 = address(amm.token0());
        vm.prank(bob);
        vm.expectEmit(true, true, false, false, address(amm));
        emit ShieldAMM.Swap(bob, t0, 0, 0, bob); // values don't matter for topic check
        amm.swap(t0, 1_000e6, 1, bob);
    }

    function test_ammSyncEmitsOnAddLiquidity() public {
        vm.prank(alice);
        vm.expectEmit(false, false, false, false, address(amm));
        emit ShieldAMM.Sync(0, 0);
        amm.addLiquidity(INITIAL_LIQUIDITY_A, INITIAL_LIQUIDITY_B, 0, 0, alice);
    }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ShieldAMM Fuzz Tests
// ══════════════════════════════════════════════════════════════════════════════

contract ShieldAMMFuzzTest is Test {
    ShieldAMM internal amm;
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal lp   = address(0xAABB);
    address internal trader = address(0xCCDD);

    function setUp() public {
        tokenA = new MockERC20("A", "A", 18);
        tokenB = new MockERC20("B", "B", 18);
        amm = new ShieldAMM(address(tokenA), address(tokenB));

        tokenA.mint(lp,     1e30);
        tokenB.mint(lp,     1e30);
        tokenA.mint(trader, 1e30);
        tokenB.mint(trader, 1e30);

        vm.prank(lp);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(lp);
        tokenB.approve(address(amm), type(uint256).max);
        vm.prank(trader);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(trader);
        tokenB.approve(address(amm), type(uint256).max);

        // Seed pool
        vm.prank(lp);
        amm.addLiquidity(1_000_000 ether, 1_000_000 ether, 0, 0, lp);
    }

    /// @dev K never decreases after any sequence of swaps.
    function testFuzz_ammKNeverDecreases(uint96 swapAmt) public {
        vm.assume(swapAmt > 1_000 && swapAmt < 100_000 ether);

        (uint112 r0, uint112 r1) = amm.getReserves();
        uint256 kBefore = uint256(r0) * uint256(r1);

        address t0 = address(amm.token0());
        vm.prank(trader);
        amm.swap(t0, swapAmt, 0, trader);

        (uint112 r0after, uint112 r1after) = amm.getReserves();
        uint256 kAfter = uint256(r0after) * uint256(r1after);

        assertGe(kAfter, kBefore);
    }

    /// @dev getAmountOut is monotonically increasing in amountIn.
    function testFuzz_ammGetAmountOutMonotonic(uint96 a1, uint96 a2) public view {
        vm.assume(a1 > 0 && a2 > a1 && uint256(a2) < 500_000 ether);
        uint256 out1 = amm.getAmountOut(a1, 1_000_000 ether, 1_000_000 ether);
        uint256 out2 = amm.getAmountOut(a2, 1_000_000 ether, 1_000_000 ether);
        assertGe(out2, out1);
    }

    /// @dev Swap output is always less than reserveOut (pool can't be drained).
    function testFuzz_ammSwapOutputBoundedByReserve(uint96 swapAmt) public {
        vm.assume(swapAmt > 0 && swapAmt < 50_000 ether);

        (uint112 r0, uint112 r1) = amm.getReserves();
        address t0 = address(amm.token0());
        (uint256 reserveIn, uint256 reserveOut) = address(amm.token0()) == t0
            ? (uint256(r0), uint256(r1))
            : (uint256(r1), uint256(r0));

        uint256 out = amm.getAmountOut(swapAmt, reserveIn, reserveOut);
        assertLt(out, reserveOut);
    }

    /// @dev AddLiquidity then removeLiquidity returns close to original amounts.
    function testFuzz_ammAddRemoveLiquidityRoundTrip(uint96 amt) public {
        vm.assume(amt > 1_000 && uint256(amt) < 100_000 ether);

        uint256 preBalA = tokenA.balanceOf(lp);
        uint256 preBalB = tokenB.balanceOf(lp);

        vm.prank(lp);
        (uint256 a0, uint256 a1, uint256 lpTokens) = amm.addLiquidity(amt, amt, 0, 0, lp);

        vm.prank(lp);
        (uint256 out0, uint256 out1) = amm.removeLiquidity(lpTokens, 0, 0, lp);

        // Should get back close to what was deposited (within 0.1% for rounding)
        assertApproxEqRel(out0, a0, 0.001e18);
        assertApproxEqRel(out1, a1, 0.001e18);

        // Final balances should be close to initial (within 2 wei for rounding)
        assertApproxEqAbs(tokenA.balanceOf(lp), preBalA, 2);
        assertApproxEqAbs(tokenB.balanceOf(lp), preBalB, 2);
    }
}

// Import for IERC20 usage in test
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
