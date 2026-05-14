// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ShieldFiBase} from "./base/ShieldFiBase.sol";

contract FuzzSuiteTest is ShieldFiBase {
    function testFuzz_depositWithdrawRoundTrip(uint96 assets) public {
        assets = uint96(bound(uint256(assets), 1_000e6, 10_000_000e6));
        vm.prank(alice);
        uint256 shares = vault.deposit(assets, alice);
        vm.prank(alice);
        uint256 out = vault.redeem(shares, alice, alice);
        assertGe(out + 3, assets);
    }

    function testFuzz_purchasePolicyPremiumPositive(uint128 coverage, uint8 days_) public {
        coverage = uint128(bound(uint256(coverage), 50_000e6, 20_000_000e6));
        vm.assume(days_ >= 1 && days_ <= 120);
        vm.prank(alice);
        vault.deposit(20_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(uint256(coverage), uint48(uint256(days_) * 1 days), 1500e8, true);
        assertGt(pid, 0);
    }

    function testFuzz_oraclePriceClaimWindow(int256 price, bool above) public {
        vm.assume(price > 2_000e8 && price < 1_000_000e8);
        vm.prank(alice);
        vault.deposit(20_000_000e6, alice);
        int256 trigger = above ? price - int256(1e8) : price + int256(1e8);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(100_000e6, uint48(30 days), trigger, above);
        feed.setAnswer(price);
        claim.processClaim(pid);
        assertTrue(policy.getPolicy(pid).claimed);
    }

    function testFuzz_vaultShareNonZero(uint96 assets) public {
        assets = uint96(bound(uint256(assets), 1e6, 5_000_000e6));
        vm.prank(bob);
        uint256 s = vault.deposit(assets, bob);
        assertGt(s, 0);
    }

    function testFuzz_treasuryFeeNonNegative(uint128 coverage, uint8 days_) public {
        coverage = uint128(bound(uint256(coverage), 50_000e6, 20_000_000e6));
        vm.assume(days_ >= 1 && days_ <= 200);
        vm.prank(alice);
        vault.deposit(20_000_000e6, alice);
        uint256 pre = collateral.balanceOf(address(treasury));
        vm.prank(bob);
        policy.purchasePolicy(uint256(coverage), uint48(uint256(days_) * 1 days), 1500e8, true);
        assertGe(collateral.balanceOf(address(treasury)), pre);
    }

    function testFuzz_claimDoesNotRevertWhenFunded(int256 finalPrice) public {
        vm.assume(finalPrice >= 1500e8 && finalPrice < 5_000_000e8);
        vm.prank(alice);
        vault.deposit(20_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1500e8, true);
        feed.setAnswer(finalPrice);
        claim.processClaim(pid);
    }

    function testFuzz_multipleDeposits(uint8 rounds, uint96 assets) public {
        rounds = uint8(bound(uint256(rounds), 1, 10));
        assets = uint96(bound(uint256(assets), 100e6, 1_000_000e6));
        for (uint256 i; i < rounds; ++i) {
            vm.prank(alice);
            vault.deposit(assets, alice);
        }
        assertGt(vault.balanceOf(alice), 0);
    }

    function testFuzz_convertToSharesMonotonic(uint96 a1, uint96 a2) public {
        a1 = uint96(bound(uint256(a1), 1e6, 2_000_000e6));
        a2 = uint96(bound(uint256(a2), 1e6, 2_000_000e6));
        vm.assume(a1 <= a2);
        uint256 s1 = vault.convertToShares(a1);
        uint256 s2 = vault.convertToShares(a2);
        assertLe(s1, s2);
    }

    function testFuzz_maxWithdrawBound(uint96 assets) public {
        assets = uint96(bound(uint256(assets), 1e6, 5_000_000e6));
        vm.prank(alice);
        vault.deposit(assets, alice);
        assertLe(vault.maxWithdraw(alice), vault.totalAssets());
    }

    function testFuzz_policyIdIncrements(uint8 n) public {
        n = uint8(bound(uint256(n), 1, 5));
        vm.prank(alice);
        vault.deposit(30_000_000e6, alice);
        uint256 last;
        for (uint256 i; i < n; ++i) {
            vm.prank(bob);
            last = policy.purchasePolicy(50_000e6, uint48(7 days), 1500e8, true);
        }
        assertEq(last, n);
    }

    function testFuzz_pauseUnpauseIdempotent(uint8 toggles) public {
        toggles = uint8(bound(uint256(toggles), 1, 6));
        for (uint256 i; i < toggles; ++i) {
            vault.pause();
            vault.unpause();
        }
        vm.prank(alice);
        vault.deposit(1e6, alice);
        assertGt(vault.balanceOf(alice), 0);
    }
}
