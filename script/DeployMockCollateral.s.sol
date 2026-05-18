// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/MockCollateral.sol";

contract DeployMockCollateral is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);
        MockCollateral token = new MockCollateral();
        vm.stopBroadcast();

        console2.log("MockCollateral", address(token));
    }
}
