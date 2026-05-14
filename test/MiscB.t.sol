// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ShieldFiBase} from "./base/ShieldFiBase.sol";

contract MiscBTest is ShieldFiBase {
    function test_bobHasCollateral() public {
        assertGt(collateral.balanceOf(bob), 0);
    }

    function test_aliceHasCollateral() public {
        assertGt(collateral.balanceOf(alice), 0);
    }

    function test_vaultShareSymbol() public view {
        assertEq(vault.symbol(), "sfSHIELD");
    }

    function test_vaultDecimals() public view {
        assertEq(vault.decimals(), collateral.decimals());
    }

    function test_policyNextIdStartsZero() public view {
        assertEq(policy.nextPolicyId(), 0);
    }

    function test_claimProcessorFeed() public view {
        assertEq(address(claim.feed()), address(feed));
    }

    function test_claimProcessorVault() public view {
        assertEq(address(claim.vault()), address(vault));
    }

    function test_claimProcessorPolicy() public view {
        assertEq(address(claim.policyManager()), address(policy));
    }

    function test_vaultImplCodeSize() public view {
        assertGt(address(vaultImpl).code.length, 0);
    }

    function test_governorName() public view {
        assertEq(governor.name(), "ShieldFi Governor");
    }

    function test_governorTimelockAddress() public view {
        assertEq(governor.timelock(), address(timelock));
    }

    function test_governorTokenAddress() public view {
        assertEq(address(governor.token()), address(govToken));
    }

    function test_govTokenName() public view {
        assertEq(govToken.name(), "ShieldFi Governance");
    }

    function test_govTokenSymbol() public view {
        assertEq(govToken.symbol(), "sSHIELD");
    }

    function test_timelockHasGovernorProposer() public view {
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
    }

    function test_timelockOpenExecutor() public view {
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)));
    }

    function test_vaultDefaultAdminIsDeployer() public view {
        assertTrue(vault.hasRole(vault.DEFAULT_ADMIN_ROLE(), deployer));
    }

    function test_policyDefaultAdminIsDeployer() public view {
        assertTrue(policy.hasRole(policy.DEFAULT_ADMIN_ROLE(), deployer));
    }

    function test_claimDefaultAdminIsDeployer() public view {
        assertTrue(claim.hasRole(claim.DEFAULT_ADMIN_ROLE(), deployer));
    }

    function test_vaultUpgraderIsDeployer() public view {
        assertTrue(vault.hasRole(vault.UPGRADER_ROLE(), deployer));
    }

    function test_vaultPauserIsDeployer() public view {
        assertTrue(vault.hasRole(vault.PAUSER_ROLE(), deployer));
    }

    function test_governorProposalThresholdReadable() public view {
        assertEq(governor.proposalThreshold(), 100_000 ether);
    }

    function test_governorVotingDelayReadable() public view {
        assertEq(governor.votingDelay(), uint256(43200));
    }

    function test_governorVotingPeriodReadable() public view {
        assertEq(governor.votingPeriod(), uint256(302400));
    }

    function test_governorQuorumAtCurrentBlock() public view {
        assertGt(governor.quorum(block.number - 1), 0);
    }

    function test_govTokenNoncesStartsZero() public view {
        assertEq(govToken.nonces(alice), 0);
    }

    function test_vaultAssetIsCollateral() public view {
        assertEq(vault.asset(), address(collateral));
    }

    function test_policyAssetIsCollateral() public view {
        assertEq(address(policy.asset()), address(collateral));
    }

    function test_treasuryImmutableTimelock() public view {
        assertEq(treasury.timelock(), address(timelock));
    }

    function test_governorStateNonexistentReverts() public {
        vm.expectRevert();
        governor.state(999_999);
    }
}
