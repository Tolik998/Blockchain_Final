// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {MockERC20} from "../../contracts/mocks/MockERC20.sol";
import {MockAggregatorV3} from "../../contracts/mocks/MockAggregatorV3.sol";
import {InsuranceVault} from "../../contracts/vault/InsuranceVault.sol";
import {PolicyManager} from "../../contracts/policy/PolicyManager.sol";
import {ClaimProcessor} from "../../contracts/claims/ClaimProcessor.sol";
import {ProtocolTreasury} from "../../contracts/treasury/ProtocolTreasury.sol";
import {ShieldGovToken} from "../../contracts/token/ShieldGovToken.sol";
import {ShieldProtocolGovernor} from "../../contracts/governance/ShieldProtocolGovernor.sol";

/**
 * @dev Shared deployment wiring for protocol tests. Uses Arbitrum-style block windows for governance timing.
 */
abstract contract ShieldFiBase is Test {
    uint48 internal constant VOTING_DELAY_BLOCKS = 43200; // ~1 day @ ~2s/block (documented approximation)
    uint32 internal constant VOTING_PERIOD_BLOCKS = 302400; // ~7 days @ ~2s/block
    uint256 internal constant GOV_QUORUM_NUMERATOR = 4; // 4%

    address internal deployer = address(this);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    MockERC20 internal collateral;
    MockAggregatorV3 internal feed;

    TimelockController internal timelock;
    ProtocolTreasury internal treasury;
    ShieldGovToken internal govToken;
    ShieldProtocolGovernor internal governor;

    InsuranceVault internal vaultImpl;
    InsuranceVault internal vault;

    PolicyManager internal policyImpl;
    PolicyManager internal policy;

    ClaimProcessor internal claimImpl;
    ClaimProcessor internal claim;

    function setUp() public virtual {
        collateral = new MockERC20("Mock USD", "mUSD", 6);
        feed = new MockAggregatorV3();
        feed.setAnswer(2000e8);

        address[] memory proposers = new address[](1);
        proposers[0] = deployer;
        address[] memory executors = new address[](1);
        executors[0] = address(0); // open executor (OZ Timelock convention)

        timelock = new TimelockController(60, proposers, executors, deployer);

        treasury = new ProtocolTreasury(address(timelock));

        govToken = new ShieldGovToken(address(timelock), deployer, 10_000_000 ether);
        uint256 proposalThreshold = 100_000 ether; // 1% of 10,000,000 tokens

        governor = new ShieldProtocolGovernor(
            govToken,
            timelock,
            VOTING_DELAY_BLOCKS,
            VOTING_PERIOD_BLOCKS,
            proposalThreshold,
            GOV_QUORUM_NUMERATOR
        );

        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
        timelock.revokeRole(timelock.PROPOSER_ROLE(), deployer);
        timelock.revokeRole(timelock.CANCELLER_ROLE(), deployer);

        govToken.delegate(address(this));
        vm.roll(block.number + 1);
        vaultImpl = new InsuranceVault();
        bytes memory vaultInit = abi.encodeCall(
            InsuranceVault.initialize,
            (collateral, "ShieldFi Vault Share", "sfSHIELD", deployer)
        );
        vault = InsuranceVault(address(new ERC1967Proxy(address(vaultImpl), vaultInit)));

        policyImpl = new PolicyManager();
        bytes memory policyInit = abi.encodeCall(
            PolicyManager.initialize,
            (collateral, vault, treasury, deployer, uint16(500), uint16(800))
        );
        policy = PolicyManager(address(new ERC1967Proxy(address(policyImpl), policyInit)));

        claimImpl = new ClaimProcessor();
        bytes memory claimInit = abi.encodeCall(
            ClaimProcessor.initialize,
            (policy, vault, feed, uint256(3600), deployer)
        );
        claim = ClaimProcessor(address(new ERC1967Proxy(address(claimImpl), claimInit)));

        policy.setClaimProcessor(address(claim));
        vault.grantRole(vault.CLAIM_PAYER_ROLE(), address(claim));

        collateral.mint(alice, 50_000_000e6);
        collateral.mint(bob, 50_000_000e6);
        vm.prank(alice);
        collateral.approve(address(vault), type(uint256).max);
        vm.prank(alice);
        collateral.approve(address(policy), type(uint256).max);
        vm.prank(bob);
        collateral.approve(address(vault), type(uint256).max);
        vm.prank(bob);
        collateral.approve(address(policy), type(uint256).max);
    }
}
