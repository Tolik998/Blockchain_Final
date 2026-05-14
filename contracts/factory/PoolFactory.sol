// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PolicyPool} from "./PolicyPool.sol";

/**
 * @title PoolFactory
 * @notice Demonstrates both CREATE and CREATE2 deployment of `PolicyPool` instances with deterministic address support.
 */
contract PoolFactory {
    uint256 public nextPoolId;

    event PoolCreated(address indexed pool, uint256 indexed poolId, address indexed asset, bool deterministic);

    function deployPoolCreate(address asset) external returns (address pool) {
        uint256 id = ++nextPoolId;
        pool = address(new PolicyPool(id, asset));
        emit PoolCreated(pool, id, asset, false);
    }

    function deployPoolCreate2(bytes32 salt, address asset) external returns (address pool) {
        uint256 id = ++nextPoolId;
        pool = address(new PolicyPool{salt: salt}(id, asset));
        emit PoolCreated(pool, id, asset, true);
    }

    function predictPoolAddress(bytes32 salt, uint256 poolId, address asset) external view returns (address predicted) {
        bytes memory bytecode = abi.encodePacked(type(PolicyPool).creationCode, abi.encode(poolId, asset));
        bytes32 bytecodeHash = keccak256(bytecode);
        predicted = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash))))
        );
    }
}
