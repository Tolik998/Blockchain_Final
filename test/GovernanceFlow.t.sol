// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

import {ShieldFiBase} from "./base/ShieldFiBase.sol";
import {ShieldGovToken} from "../contracts/token/ShieldGovToken.sol";

contract GovernanceFlowTest is ShieldFiBase {
    function test_proposalLifecycleMintsThroughTimelock() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(govToken);
        values[0] = 0;
        calldatas[0] = abi.encodeCall(ShieldGovToken.mint, (bob, 10 ether));
        string memory description = "mint bob";
        bytes32 descHash = keccak256(bytes(description));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));

        vm.roll(governor.proposalSnapshot(proposalId) + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Active));

        governor.castVote(proposalId, 1);

        vm.roll(governor.proposalDeadline(proposalId) + 1);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));

        governor.queue(targets, values, calldatas, descHash);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));

        vm.warp(block.timestamp + timelock.getMinDelay() + 1);

        uint256 pre = govToken.balanceOf(bob);
        governor.execute(targets, values, calldatas, descHash);
        assertEq(govToken.balanceOf(bob), pre + 10 ether);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));
    }

    function test_cannotProposeWithoutVotes() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        targets[0] = address(govToken);
        values[0] = 0;
        calldatas[0] = abi.encodeCall(ShieldGovToken.mint, (bob, 1 ether));

        vm.prank(bob);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "bob proposal");
    }
}
