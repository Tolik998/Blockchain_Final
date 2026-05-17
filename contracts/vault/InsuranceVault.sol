// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title InsuranceVault
 * @notice ERC-4626 underwriting vault with pausing, reentrancy protection, and claim payouts restricted to the claim processor.
 * @dev Upgradeable via UUPS. Underwriter yield is realized when premiums are transferred to the vault without minting shares.
 */
contract InsuranceVault is
    Initializable,
    ERC4626Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant CLAIM_PAYER_ROLE = keccak256("CLAIM_PAYER_ROLE");

    uint128 public totalPayouts;
    uint256[50] private __gap;

    event ClaimPayout(address indexed to, uint256 assets);

    error ZeroAddress();
    error ZeroAmount();
    error PayoutAccountingOverflow();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 asset_,
        string memory shareName,
        string memory shareSymbol,
        address admin
    ) external initializer {
        if (admin == address(0)) revert ZeroAddress();
        __ERC20_init(shareName, shareSymbol);
        __ERC4626_init(asset_);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    /**
     * @notice Pull underlying assets from the vault to satisfy an approved claim.
     * @dev CEI: accounting is updated before the external ERC20 transfer.
     */
    function payout(address to, uint256 assets) external nonReentrant whenNotPaused onlyRole(CLAIM_PAYER_ROLE) {
        if (to == address(0)) revert ZeroAddress();
        if (assets == 0) revert ZeroAmount();
        if (assets > type(uint128).max - totalPayouts) revert PayoutAccountingOverflow();

        totalPayouts += uint128(assets);

        IERC20(asset()).safeTransfer(to, assets);
        emit ClaimPayout(to, assets);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override nonReentrant whenNotPaused returns (uint256 shares) {
        return super.deposit(assets, receiver);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override nonReentrant whenNotPaused returns (uint256 assets) {
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant whenNotPaused returns (uint256 shares) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override nonReentrant whenNotPaused returns (uint256 assets) {
        return super.redeem(shares, receiver, owner);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE) {
        if (newImplementation == address(0)) revert ZeroAddress();
    }

    uint256 public constant VERSION = 1;
}
