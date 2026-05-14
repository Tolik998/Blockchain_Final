// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IClaimProcessor
 * @notice Minimal surface used by the policy manager for claim lifecycle coordination.
 */
interface IClaimProcessor {
    function claimProcessorVersion() external pure returns (uint256);
}
