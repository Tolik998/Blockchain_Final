// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";

/**
 * @title VerifyShieldFi
 * @notice Thin wrapper around `forge verify-contract` targets for CI/manual verification.
 * @dev Example (run from repo root):
 *      `forge script script/VerifyShieldFi.s.sol --sig "logHelp()" -vvv`
 */
contract VerifyShieldFi is Script {
    function logHelp() external {
        console2.log("Use forge verify-contract with:");
        console2.log("  --compiler-version 0.8.26");
        console2.log("  --etherscan-api-key $ETHERSCAN_API_KEY");
        console2.log("  --chain arbitrum-sepolia");
        console2.log("Point --constructor-args or --watch flags as needed for proxies.");
    }
}
