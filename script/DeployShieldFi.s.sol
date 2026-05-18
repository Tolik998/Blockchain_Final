// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {InsuranceVault} from "../contracts/vault/InsuranceVault.sol";
import {PolicyManager} from "../contracts/policy/PolicyManager.sol";
import {ClaimProcessor} from "../contracts/claims/ClaimProcessor.sol";
import {ProtocolTreasury} from "../contracts/treasury/ProtocolTreasury.sol";
import {ShieldGovToken} from "../contracts/token/ShieldGovToken.sol";
import {ShieldProtocolGovernor} from "../contracts/governance/ShieldProtocolGovernor.sol";
import {AggregatorV3Interface} from "../contracts/interfaces/AggregatorV3Interface.sol";
import {PolicyNFT} from "../contracts/token/PolicyNFT.sol";
import {ShieldAMM} from "../contracts/amm/ShieldAMM.sol";

/**
 * @title DeployShieldFi
 * @notice Broadcast deployment for Arbitrum Sepolia (or any chain) using env configuration.
 * @dev Required env:
 *      - `PRIVATE_KEY`
 *      - `COLLATERAL_ASSET` (ERC20 underlying for ERC4626 vault + premiums)
 *      - `CHAINLINK_AGGREGATOR` (AggregatorV3-compatible feed for claim triggers)
 * Optional:
 *      - `TIMELOCK_MIN_DELAY_SECONDS` (default 86400)
 *      - `GOV_INITIAL_SUPPLY` (default 10_000_000 ether)
 *      - `GOV_PROPOSAL_THRESHOLD` (default 100_000 ether)
 *      - `ORACLE_HEARTBEAT_SECONDS` (default 3600)
 *      - `TREASURY_FEE_BPS` (default 500)
 *      - `ANNUAL_PREMIUM_BPS` (default 800)
 */
contract DeployShieldFi is Script {
    uint48 public constant VOTING_DELAY_BLOCKS = 43200;
    uint32 public constant VOTING_PERIOD_BLOCKS = 302400;

    TimelockController public timelock;
    ProtocolTreasury public treasury;
    ShieldGovToken public gov;
    ShieldProtocolGovernor public governor;
    InsuranceVault public vault;
    PolicyManager public policy;
    ClaimProcessor public claim;
    PolicyNFT public policyNFT;
    ShieldAMM public amm;

    function _deployPolicyManager(
        address collateral,
        InsuranceVault vault_,
        ProtocolTreasury treasury_,
        address deployer,
        uint16 treasuryFeeBps,
        uint16 annualPremiumBps
    ) internal returns (PolicyManager) {
        PolicyManager pImpl = new PolicyManager();
        bytes memory pInit = abi.encodeCall(
            PolicyManager.initialize,
            (IERC20(collateral), vault_, treasury_, deployer, treasuryFeeBps, annualPremiumBps)
        );

        return PolicyManager(address(new ERC1967Proxy(address(pImpl), pInit)));
    }

    function _deployClaimProcessor(
        PolicyManager policy_,
        InsuranceVault vault_,
        address feed,
        uint256 heartbeat,
        address deployer
    ) internal returns (ClaimProcessor) {
        ClaimProcessor cImpl = new ClaimProcessor();
        bytes memory cInit = abi.encodeCall(
            ClaimProcessor.initialize,
            (policy_, vault_, AggregatorV3Interface(feed), heartbeat, deployer)
        );

        return ClaimProcessor(address(new ERC1967Proxy(address(cImpl), cInit)));
    }

    function _deployTimelock(address deployer) internal returns (TimelockController) {
        address[] memory proposers = new address[](1);
        proposers[0] = deployer;
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        uint256 minDelay = vm.envOr("TIMELOCK_MIN_DELAY_SECONDS", uint256(86400));
        return new TimelockController(minDelay, proposers, executors, deployer);
    }

    function _deployGovernance(
        TimelockController timelockController,
        address deployer
    ) internal returns (ShieldGovToken govToken, ShieldProtocolGovernor governorContract) {
        uint256 initialSupply = vm.envOr("GOV_INITIAL_SUPPLY", uint256(10_000_000 ether));
        govToken = new ShieldGovToken(address(timelockController), deployer, initialSupply);

        uint256 proposalThreshold = vm.envOr("GOV_PROPOSAL_THRESHOLD", uint256(100_000 ether));
        governorContract = new ShieldProtocolGovernor(
            govToken,
            timelockController,
            VOTING_DELAY_BLOCKS,
            VOTING_PERIOD_BLOCKS,
            proposalThreshold,
            4
        );

        timelockController.grantRole(timelockController.PROPOSER_ROLE(), address(governorContract));
        timelockController.grantRole(timelockController.CANCELLER_ROLE(), address(governorContract));
        timelockController.revokeRole(timelockController.PROPOSER_ROLE(), deployer);
        timelockController.revokeRole(timelockController.CANCELLER_ROLE(), deployer);
    }

    function _deployVault(address collateral, address deployer) internal returns (InsuranceVault) {
        InsuranceVault vImpl = new InsuranceVault();
        bytes memory vInit = abi.encodeCall(
            InsuranceVault.initialize,
            (IERC20(collateral), "ShieldFi Vault Share", "sfSHIELD", deployer)
        );
        return InsuranceVault(address(new ERC1967Proxy(address(vImpl), vInit)));
    }

    function _deploy(address deployer) internal {
        timelock = _deployTimelock(deployer);
        treasury = new ProtocolTreasury(address(timelock));
        (gov, governor) = _deployGovernance(timelock, deployer);

        address collateral = vm.envAddress("COLLATERAL_ASSET");
        address feed = vm.envAddress("CHAINLINK_AGGREGATOR");

        vault = _deployVault(collateral, deployer);

        uint16 treasuryFeeBps = uint16(vm.envOr("TREASURY_FEE_BPS", uint256(500)));
        uint16 annualPremiumBps = uint16(vm.envOr("ANNUAL_PREMIUM_BPS", uint256(800)));

        policy = _deployPolicyManager(
            collateral,
            vault,
            treasury,
            deployer,
            treasuryFeeBps,
            annualPremiumBps
        );

        uint256 heartbeat = vm.envOr("ORACLE_HEARTBEAT_SECONDS", uint256(3600));
        claim = _deployClaimProcessor(
            policy,
            vault,
            feed,
            heartbeat,
            deployer
        );

        policy.setClaimProcessor(address(claim));
        vault.grantRole(vault.CLAIM_PAYER_ROLE(), address(claim));

        // Deploy PolicyNFT — ERC-721 representing each policy
        policyNFT = new PolicyNFT(deployer, address(policy));

        // Deploy ShieldAMM — constant-product AMM for collateral/govToken pair
        amm = new ShieldAMM(collateral, address(gov));
    }

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        address deployer = vm.addr(pk);

        _deploy(deployer);

        vm.stopBroadcast();

        console2.log("Timelock", address(timelock));
        console2.log("Treasury", address(treasury));
        console2.log("GovToken", address(gov));
        console2.log("Governor", address(governor));
        console2.log("Vault", address(vault));
        console2.log("PolicyManager", address(policy));
        console2.log("ClaimProcessor", address(claim));
        console2.log("PolicyNFT", address(policyNFT));
        console2.log("ShieldAMM", address(amm));
    }
}
