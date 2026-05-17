// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {InsuranceVault} from "../vault/InsuranceVault.sol";
import {ProtocolTreasury} from "../treasury/ProtocolTreasury.sol";
import {IPolicyManager} from "../interfaces/IPolicyManager.sol";

/**
 * @title PolicyManager
 * @notice Registers parametric policies, collects premiums, routes fees to the timelock treasury, and coordinates claim settlement.
 */
contract PolicyManager is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    IPolicyManager
{
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IERC20 public asset;
    InsuranceVault public vault;
    ProtocolTreasury public treasury;

    uint256 public nextPolicyId;
    uint16 public treasuryFeeBps;
    uint16 public annualPremiumBps;
    address public claimProcessor;

    struct Policy {
        address buyer;
        uint48 purchasedAt;
        uint48 expiresAt;
        bool triggerAbove;
        bool claimed;
        bool active;
        uint256 coverageAmount;
        uint256 premiumPaid;
        int256 triggerPrice1e8;
    }

    mapping(uint256 policyId => Policy) private _policies;

    event PolicyPurchased(
        uint256 indexed policyId,
        address indexed buyer,
        uint256 coverage,
        uint256 premium,
        uint48 expiration
    );
    event PolicyDeactivated(uint256 indexed policyId);
    event ClaimRecorded(uint256 indexed policyId, address indexed beneficiary, uint256 amount);
    event ClaimProcessorSet(address indexed processor);

    error ZeroAddress();
    error InactivePolicy();
    error AlreadyClaimed();
    error ExpiredPolicy();
    error InvalidDuration();
    error InvalidCoverage();
    error InvalidFee();
    error NotClaimProcessor();
    error NotClaimable();

    modifier onlyClaimProcessor() {
        if (msg.sender != claimProcessor) revert NotClaimProcessor();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 asset_,
        InsuranceVault vault_,
        ProtocolTreasury treasury_,
        address admin,
        uint16 treasuryFeeBps_,
        uint16 annualPremiumBps_
    ) external initializer {
        if (address(asset_) == address(0) || address(vault_) == address(0) || address(treasury_) == address(0)) {
            revert ZeroAddress();
        }
        if (admin == address(0)) revert ZeroAddress();
        if (treasuryFeeBps_ > 5_000) revert InvalidFee();

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        asset = asset_;
        vault = vault_;
        treasury = treasury_;
        treasuryFeeBps = treasuryFeeBps_;
        annualPremiumBps = annualPremiumBps_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    function setClaimProcessor(address processor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (processor == address(0)) revert ZeroAddress();
        claimProcessor = processor;
        emit ClaimProcessorSet(processor);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function computePremium(uint256 coverageAmount, uint48 durationSeconds) public view returns (uint256 premium) {
        if (coverageAmount == 0) revert InvalidCoverage();
        if (durationSeconds < 1 hours || durationSeconds > 365 days) revert InvalidDuration();
        premium =
            (coverageAmount * uint256(annualPremiumBps) * uint256(durationSeconds)) /
            (10_000 * uint256(365 days));
        if (premium == 0) revert InvalidCoverage();
    }

    function purchasePolicy(
        uint256 coverageAmount,
        uint48 durationSeconds,
        int256 triggerPrice1e8,
        bool triggerAbove
    ) external nonReentrant whenNotPaused returns (uint256 policyId) {
        uint256 premium = computePremium(coverageAmount, durationSeconds);

        IERC20 a = asset;
        a.safeTransferFrom(msg.sender, address(this), premium);

        uint256 fee = (premium * uint256(treasuryFeeBps)) / 10_000;
        uint256 toVault = premium - fee;
        a.safeTransfer(address(treasury), fee);
        a.safeTransfer(address(vault), toVault);

        policyId = ++nextPolicyId;
        _policies[policyId] = Policy({
            buyer: msg.sender,
            coverageAmount: coverageAmount,
            premiumPaid: premium,
            purchasedAt: uint48(block.timestamp),
            expiresAt: uint48(block.timestamp + durationSeconds),
            triggerPrice1e8: triggerPrice1e8,
            triggerAbove: triggerAbove,
            claimed: false,
            active: true
        });

        emit PolicyPurchased(policyId, msg.sender, coverageAmount, premium, uint48(block.timestamp + durationSeconds));
    }

    function deactivatePolicy(uint256 policyId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Policy storage p = _policies[policyId];
        if (!p.active) revert InactivePolicy();
        p.active = false;
        emit PolicyDeactivated(policyId);
    }

    function getPolicy(uint256 policyId) external view returns (PolicyView memory) {
        Policy storage p = _policies[policyId];
        return
            PolicyView({
                buyer: p.buyer,
                coverageAmount: p.coverageAmount,
                premiumPaid: p.premiumPaid,
                purchasedAt: p.purchasedAt,
                expiresAt: p.expiresAt,
                triggerPrice1e8: p.triggerPrice1e8,
                triggerAbove: p.triggerAbove,
                claimed: p.claimed,
                active: p.active
            });
    }

    function isClaimable(uint256 policyId, int256 oraclePrice1e8) public view returns (bool) {
        Policy storage p = _policies[policyId];
        if (!p.active || p.claimed) return false;
        if (block.timestamp > p.expiresAt) return false;
        if (p.triggerAbove) {
            return oraclePrice1e8 >= p.triggerPrice1e8;
        }
        return oraclePrice1e8 <= p.triggerPrice1e8;
    }

    /**
     * @notice Atomically validates a claim, marks the policy settled, and returns payout parameters to the claim processor.
     * @dev Must only be invoked by the configured claim processor after oracle validation.
     */
    function consumeClaim(
        uint256 policyId,
        int256 oraclePrice1e8
    ) external onlyClaimProcessor nonReentrant returns (address beneficiary, uint256 payoutAmount) {
        Policy storage p = _policies[policyId];
        if (!p.active) revert InactivePolicy();
        if (p.claimed) revert AlreadyClaimed();
        if (block.timestamp > p.expiresAt) revert ExpiredPolicy();
        if (!isClaimable(policyId, oraclePrice1e8)) revert NotClaimable();

        beneficiary = p.buyer;
        payoutAmount = p.coverageAmount;

        p.claimed = true;
        p.active = false;

        emit ClaimRecorded(policyId, beneficiary, payoutAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE) {
        if (newImplementation == address(0)) revert ZeroAddress();
    }
}
