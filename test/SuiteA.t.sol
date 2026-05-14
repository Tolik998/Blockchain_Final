// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ShieldFiBase} from "./base/ShieldFiBase.sol";
import {GasOptimizedMath} from "../contracts/math/GasOptimizedMath.sol";
import {InsuranceVaultV2} from "../contracts/vault/InsuranceVaultV2.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IPolicyManager} from "../contracts/interfaces/IPolicyManager.sol";
import {ClaimProcessor} from "../contracts/claims/ClaimProcessor.sol";
import {PolicyManager} from "../contracts/policy/PolicyManager.sol";

contract SuiteATest is ShieldFiBase {
    function testFuzz_premiumMathMatches(uint128 coverage, uint16 durationDays, uint16 rateBps) public {
        vm.assume(coverage > 10_000);
        vm.assume(durationDays > 0 && durationDays <= 365);
        vm.assume(rateBps > 0 && rateBps <= 2000);
        uint256 duration = uint256(durationDays) * 1 days;
        uint256 year = 365 days;
        vm.assume(uint256(coverage) * uint256(rateBps) <= type(uint256).max / duration);
        uint256 lhs = GasOptimizedMath.premiumMulDivSolidity(coverage, rateBps, duration, year);
        uint256 rhs = GasOptimizedMath.premiumMulDivYul(coverage, rateBps, duration, year);
        assertEq(lhs, rhs);
    }

    function testFuzz_premiumMonotonicInDuration(uint128 coverage, uint32 d1, uint32 d2) public {
        vm.assume(coverage > 10_000);
        vm.assume(d1 >= 1 hours && d2 >= 1 hours && d1 <= 365 days && d2 <= 365 days);
        vm.assume(d1 <= d2);
        uint256 p1 = GasOptimizedMath.premiumMulDivSolidity(coverage, 500, uint256(d1), 365 days);
        uint256 p2 = GasOptimizedMath.premiumMulDivSolidity(coverage, 500, uint256(d2), 365 days);
        assertLe(p1, p2);
    }

    function testFuzz_premiumMonotonicInRate(uint128 coverage, uint16 r1, uint16 r2) public {
        vm.assume(coverage > 10_000);
        vm.assume(r1 > 0 && r2 <= 5000 && r1 <= r2);
        uint256 duration = 30 days;
        uint256 p1 = GasOptimizedMath.premiumMulDivSolidity(coverage, r1, duration, 365 days);
        uint256 p2 = GasOptimizedMath.premiumMulDivSolidity(coverage, r2, duration, 365 days);
        assertLe(p1, p2);
    }

    function test_gas_mulDivBenchmarkRecordsUsage() public {
        uint256 coverage = 1_000_000e6;
        uint256 rate = 800;
        uint256 duration = 30 days;
        uint256 year = 365 days;

        uint256 g0 = gasleft();
        GasOptimizedMath.premiumMulDivSolidity(coverage, rate, duration, year);
        uint256 solUsed = g0 - gasleft();

        uint256 h0 = gasleft();
        GasOptimizedMath.premiumMulDivYul(coverage, rate, duration, year);
        uint256 yulUsed = h0 - gasleft();

        assertGt(solUsed, 0);
        assertGt(yulUsed, 0);
    }

    function test_upgradeVaultToV2() public {
        InsuranceVaultV2 impl2 = new InsuranceVaultV2();
        vm.prank(deployer);
        UUPSUpgradeable(address(vault)).upgradeToAndCall(address(impl2), "");
        InsuranceVaultV2 prox = InsuranceVaultV2(address(vault));
        assertEq(prox.version(), 2);
        vm.prank(deployer);
        prox.setProtocolFeeBps(10);
        assertEq(prox.protocolFeeBps(), 10);
    }

    function test_vaultPreviewDepositPositive() public {
        vm.prank(alice);
        uint256 assets = 1_000_000e6;
        uint256 shares = vault.previewDeposit(assets);
        assertGt(shares, 0);
    }

    function test_vaultPreviewMintRoundTrip() public {
        vm.prank(alice);
        uint256 shares = vault.previewMint(1_000e6);
        assertGt(shares, 0);
    }

    function test_vaultTotalAssetsTracksDeposits() public {
        vm.prank(alice);
        vault.deposit(3_000_000e6, alice);
        assertEq(vault.totalAssets(), 3_000_000e6);
    }

    function test_claimProcessorPauseBlocks() public {
        claim.pause();
        vm.expectRevert();
        claim.processClaim(1);
    }

    function test_policyPauseBlocksPurchase() public {
        policy.pause();
        vm.prank(alice);
        vm.expectRevert();
        policy.purchasePolicy(10_000e6, uint48(7 days), 1500e8, true);
    }

    function test_badOracleAnswerReverts() public {
        feed.setAnswer(0);
        vm.prank(alice);
        vault.deposit(5_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(50_000e6, uint48(30 days), 1500e8, true);
        vm.expectRevert(ClaimProcessor.BadAnswer.selector);
        claim.processClaim(pid);
    }

    function test_treasuryReceivesERC20Premiums() public {
        vm.prank(alice);
        vault.deposit(5_000_000e6, alice);
        uint256 pre = collateral.balanceOf(address(treasury));
        vm.prank(bob);
        policy.purchasePolicy(100_000e6, uint48(30 days), 1500e8, true);
        assertGt(collateral.balanceOf(address(treasury)), pre);
    }

    function test_vaultShareBalanceOfAlice() public {
        vm.prank(alice);
        uint256 s = vault.deposit(1_000_000e6, alice);
        assertEq(vault.balanceOf(alice), s);
    }

    function test_convertToAssetsMatches() public {
        vm.prank(alice);
        uint256 s = vault.deposit(2_000_000e6, alice);
        assertEq(vault.convertToAssets(s), 2_000_000e6);
    }

    function test_maxDepositNonZero() public view {
        assertGt(vault.maxDeposit(alice), 0);
    }

    function test_maxMintNonZero() public view {
        assertGt(vault.maxMint(alice), 0);
    }

    function test_claimIncreasesTotalPayouts() public {
        vm.prank(alice);
        vault.deposit(10_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1500e8, true);
        uint128 pre = vault.totalPayouts();
        feed.setAnswer(1600e8);
        claim.processClaim(pid);
        assertGt(vault.totalPayouts(), pre);
    }

    function test_expiredPolicyCannotClaim() public {
        vm.prank(alice);
        vault.deposit(10_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(1 hours), 1500e8, true);
        feed.setAnswer(1600e8);
        vm.warp(block.timestamp + 2 hours);
        vm.expectRevert(PolicyManager.ExpiredPolicy.selector);
        claim.processClaim(pid);
    }

    function test_triggerBelowPath() public {
        vm.prank(alice);
        vault.deposit(10_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1000e8, false);
        feed.setAnswer(900e8);
        claim.processClaim(pid);
        IPolicyManager.PolicyView memory pv = policy.getPolicy(pid);
        assertTrue(pv.claimed);
    }

    function test_governorQuorumNumerator() public view {
        assertEq(governor.quorumNumerator(), 4);
    }

    function test_timelockMinDelay() public view {
        assertEq(timelock.getMinDelay(), 60);
    }

    function test_collateralSymbol() public view {
        assertEq(collateral.symbol(), "mUSD");
    }

    function test_vaultName() public view {
        assertEq(vault.name(), "ShieldFi Vault Share");
    }

    function test_policyAnnualBps() public view {
        assertEq(policy.annualPremiumBps(), 800);
    }

    function test_policyTreasuryFeeBps() public view {
        assertEq(policy.treasuryFeeBps(), 500);
    }

    function test_claimHeartbeat() public view {
        assertEq(claim.heartbeatSeconds(), 3600);
    }
}
