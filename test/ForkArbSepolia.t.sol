// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../contracts/mocks/MockERC20.sol";
import {AggregatorV3Interface} from "../contracts/interfaces/AggregatorV3Interface.sol";

contract ForkArbSepoliaTest is Test {
    function testFork_chainIdMatchesArbSepolia() public {
        string memory rpc = vm.envOr("ARB_SEPOLIA_RPC_URL", string("https://sepolia-rollup.arbitrum.io/rpc"));
        vm.createSelectFork(rpc);
        assertEq(block.chainid, 11155111);
    }

    function testFork_blockNumberAdvances() public {
        vm.createSelectFork(vm.envOr("ARB_SEPOLIA_RPC_URL", string("https://sepolia-rollup.arbitrum.io/rpc")));
        uint256 b1 = block.number;
        vm.roll(b1 + 1000);
        assertGt(block.number, b1);
    }

    function testFork_readEthUsdIfConfigured() public {
        vm.createSelectFork(vm.envOr("ARB_SEPOLIA_RPC_URL", string("https://sepolia-rollup.arbitrum.io/rpc")));
        address feed = vm.envOr("ARB_SEPOLIA_ETH_USD_FEED", address(0));
        if (feed == address(0)) {
            return;
        }
        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(feed).latestRoundData();
        assertTrue(answer > 0);
        assertTrue(updatedAt > 0);
    }

    function testFork_deployMockErc20() public {
        vm.createSelectFork(vm.envOr("ARB_SEPOLIA_RPC_URL", string("https://sepolia-rollup.arbitrum.io/rpc")));
        MockERC20 m = new MockERC20("Fork", "F", 6);
        assertEq(m.decimals(), 6);
    }
}
