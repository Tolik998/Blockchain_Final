// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title PolicyPool
 * @notice Minimal pool contract deployed by `PoolFactory` to demonstrate CREATE / CREATE2 deployment patterns.
 */
contract PolicyPool {
    uint256 public immutable poolId;
    address public immutable asset;

    constructor(uint256 poolId_, address asset_) {
        poolId = poolId_;
        asset = asset_;
    }
}
