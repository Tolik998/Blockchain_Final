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
import {PolicyManager} from "../policy/PolicyManager.sol";
import {IPolicyManager} from "../interfaces/IPolicyManager.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

/**
 * @title ClaimProcessor
 * @notice Validates Chainlink answers with staleness guards, then settles policies against vault liquidity.
 */
contract ClaimProcessor is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    PolicyManager public policyManager;
    InsuranceVault public vault;
    AggregatorV3Interface public feed;
    uint256 public heartbeatSeconds;

    event ClaimProcessed(uint256 indexed policyId, address indexed beneficiary, uint256 payout, int256 oraclePrice);

    error ZeroAddress();
    error InvalidHeartbeat();
    error StaleOracle();
    error BadAnswer();
    error IncompleteRound();
    error InsufficientLiquidity();
    error ClaimSettlementMismatch();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        PolicyManager policyManager_,
        InsuranceVault vault_,
        AggregatorV3Interface feed_,
        uint256 heartbeatSeconds_,
        address admin
    ) external initializer {
        if (address(policyManager_) == address(0) || address(vault_) == address(0) || address(feed_) == address(0)) {
            revert ZeroAddress();
        }
        if (admin == address(0)) revert ZeroAddress();
        if (heartbeatSeconds_ == 0) revert InvalidHeartbeat();

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        policyManager = policyManager_;
        vault = vault_;
        feed = feed_;
        heartbeatSeconds = heartbeatSeconds_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Executes a claim if the oracle condition is met and the vault can cover the payout.
     * @dev CEI: oracle checks first, policy state is updated in `PolicyManager.consumeClaim`, then the vault transfers assets.
     */
    function processClaim(uint256 policyId) external nonReentrant whenNotPaused {
        IPolicyManager.PolicyView memory pv = policyManager.getPolicy(policyId);
        if (block.timestamp > pv.expiresAt) revert PolicyManager.ExpiredPolicy();

        int256 price = _readOracle();

        uint256 payout = pv.coverageAmount;
        IERC20 a = IERC20(vault.asset());
        uint256 bal = a.balanceOf(address(vault));
        if (bal < payout) revert InsufficientLiquidity();

        (address beneficiary, uint256 amount) = policyManager.consumeClaim(policyId, price);
        if (amount != payout || beneficiary != pv.buyer) {
            revert ClaimSettlementMismatch();
        }

        vault.payout(beneficiary, amount);
        emit ClaimProcessed(policyId, beneficiary, amount, price);
    }

    function claimProcessorVersion() external pure returns (uint256) {
        return 1;
    }

    function _readOracle() internal view returns (int256 price) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        if (answer <= 0) revert BadAnswer();
        if (answeredInRound < roundId) revert IncompleteRound();
        if (updatedAt > block.timestamp) revert StaleOracle();
        if (block.timestamp - updatedAt > heartbeatSeconds) revert StaleOracle();
        return answer;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {
        if (newImplementation == address(0)) revert ZeroAddress();
    }
}
