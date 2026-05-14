// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {InsuranceVault} from "./InsuranceVault.sol";

/**
 * @title InsuranceVaultV2
 * @notice V2 adds an explicit protocol fee knob for future premium routing without breaking storage layout.
 * @dev Inherits V1 storage then appends new fields, consuming one slot from the inherited gap pattern.
 */
contract InsuranceVaultV2 is InsuranceVault {
    uint128 public protocolFeeBps;
    uint128 private __reserved;
    uint256[49] private __gapV2;

    error FeeTooHigh();

    function setProtocolFeeBps(uint128 feeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (feeBps > 2_000) revert FeeTooHigh();
        protocolFeeBps = feeBps;
    }

    function version() external pure returns (uint256) {
        return 2;
    }
}
