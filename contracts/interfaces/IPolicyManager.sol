// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IPolicyManager
 * @notice Read-only policy view for oracle/claim modules and integration tests.
 */
interface IPolicyManager {
    struct PolicyView {
        address buyer;
        uint256 coverageAmount;
        uint256 premiumPaid;
        uint48 purchasedAt;
        uint48 expiresAt;
        int256 triggerPrice1e8;
        bool triggerAbove;
        bool claimed;
        bool active;
    }

    function getPolicy(uint256 policyId) external view returns (PolicyView memory);

    function isClaimable(uint256 policyId, int256 oraclePrice1e8) external view returns (bool);
}
