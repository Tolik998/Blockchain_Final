// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {VulnerableEthReentrancyLesson} from "../contracts/lessons/vulnerable/VulnerableEthReentrancyLesson.sol";
import {FixedEthReentrancyLesson} from "../contracts/lessons/fixed/FixedEthReentrancyLesson.sol";
import {VulnerableMintAccessLesson} from "../contracts/lessons/vulnerable/VulnerableMintAccessLesson.sol";
import {FixedMintAccessLesson} from "../contracts/lessons/fixed/FixedMintAccessLesson.sol";
import {ReentrancyAttacker} from "./helpers/ReentrancyAttacker.sol";
import {FixedReentrancyAttacker} from "./helpers/FixedReentrancyAttacker.sol";

contract LessonsTest is Test {
    function test_vulnerableLessonDrainsETH() public {
        VulnerableEthReentrancyLesson v = new VulnerableEthReentrancyLesson();
        address victim = address(0x555);
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        v.deposit{value: 10 ether}();

        ReentrancyAttacker a = new ReentrancyAttacker(v);
        vm.deal(address(a), 2 ether);
        a.attack{value: 1 ether}(1 ether);
        assertEq(address(v).balance, 0);
        assertGt(address(a).balance, 2 ether);
    }

    function test_fixedLessonReentrancyGuard() public {
        FixedEthReentrancyLesson v = new FixedEthReentrancyLesson();
        FixedReentrancyAttacker a = new FixedReentrancyAttacker(v);
        vm.deal(address(a), 3 ether);
        vm.expectRevert();
        a.start{value: 2 ether}();
    }

    function test_fixedWithdrawHappyPath() public {
        FixedEthReentrancyLesson v = new FixedEthReentrancyLesson();
        address user = address(0x1234);
        vm.deal(user, 2 ether);
        vm.prank(user);
        v.deposit{value: 1 ether}();
        vm.prank(user);
        v.withdrawSafe(1 ether);
        assertEq(v.balances(user), 0);
    }

    function test_vulnerableMintAnyone() public {
        VulnerableMintAccessLesson v = new VulnerableMintAccessLesson();
        vm.prank(address(0xBEEF));
        v.mint(address(0xBEEF), 1 ether);
        assertEq(v.balanceOf(address(0xBEEF)), 1 ether);
    }

    function test_fixedMintRequiresRole() public {
        FixedMintAccessLesson v = new FixedMintAccessLesson(address(this));
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        v.mint(address(0xBEEF), 1 ether);
    }

    function test_fixedMintAdminCanMint() public {
        FixedMintAccessLesson v = new FixedMintAccessLesson(address(this));
        v.mint(address(0xBEEF), 2 ether);
        assertEq(v.balanceOf(address(0xBEEF)), 2 ether);
    }
}
