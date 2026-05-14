// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ShieldFiBase} from "./base/ShieldFiBase.sol";
import {PoolFactory} from "../contracts/factory/PoolFactory.sol";
import {PolicyPool} from "../contracts/factory/PolicyPool.sol";
import {IPolicyManager} from "../contracts/interfaces/IPolicyManager.sol";
import {ClaimProcessor} from "../contracts/claims/ClaimProcessor.sol";

contract ProtocolCoreTest is ShieldFiBase {
    function test_collateralDecimals() public view {
        assertEq(collateral.decimals(), 6);
    }

    function test_vaultAsset() public view {
        assertEq(vault.asset(), address(collateral));
    }

    function test_policyClaimProcessorWired() public view {
        assertEq(policy.claimProcessor(), address(claim));
    }

    function test_vaultClaimRoleGranted() public view {
        assertTrue(vault.hasRole(vault.CLAIM_PAYER_ROLE(), address(claim)));
    }

    function test_aliceDepositMintsShares() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1_000_000e6, alice);
        assertGt(shares, 0);
        assertEq(collateral.balanceOf(address(vault)), 1_000_000e6);
    }

    function test_bobWithdrawAfterDeposit() public {
        vm.prank(bob);
        uint256 shares = vault.deposit(2_000_000e6, bob);
        vm.prank(bob);
        vault.redeem(shares, bob, bob);
        assertEq(vault.balanceOf(bob), 0);
    }

    function test_pauseBlocksDeposit() public {
        vault.pause();
        vm.prank(alice);
        vm.expectRevert();
        vault.deposit(1, alice);
    }

    function test_unpauseRestoresDeposit() public {
        vault.pause();
        vault.unpause();
        vm.prank(alice);
        vault.deposit(1_000e6, alice);
    }

    function test_purchasePolicyRoutesFees() public {
        vm.prank(alice);
        vault.deposit(5_000_000e6, alice);

        uint256 preTreasury = collateral.balanceOf(address(treasury));
        uint256 preVault = collateral.balanceOf(address(vault));

        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(100_000e6, uint48(30 days), 1500e8, true);

        assertEq(pid, 1);
        assertGt(collateral.balanceOf(address(treasury)), preTreasury);
        assertGt(collateral.balanceOf(address(vault)), preVault);
    }

    function test_policyViewMatches() public {
        vm.prank(alice);
        vault.deposit(5_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(50_000e6, uint48(10 days), 2500e8, false);
        IPolicyManager.PolicyView memory pv = policy.getPolicy(pid);
        assertEq(pv.buyer, bob);
        assertEq(pv.coverageAmount, 50_000e6);
        assertTrue(pv.active);
        assertFalse(pv.claimed);
    }

    function test_claimPaysBuyer() public {
        vm.prank(alice);
        vault.deposit(10_000_000e6, alice);

        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1500e8, true);

        feed.setAnswer(1600e8);
        uint256 pre = collateral.balanceOf(bob);
        claim.processClaim(pid);
        assertGt(collateral.balanceOf(bob), pre);
    }

    function test_doubleClaimReverts() public {
        vm.prank(alice);
        vault.deposit(10_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1500e8, true);
        feed.setAnswer(1600e8);
        claim.processClaim(pid);
        vm.expectRevert();
        claim.processClaim(pid);
    }

    function test_staleOracleReverts() public {
        vm.prank(alice);
        vault.deposit(10_000_000e6, alice);
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1500e8, true);
        feed.setAnswer(1600e8);
        feed.setStale();
        vm.expectRevert(ClaimProcessor.StaleOracle.selector);
        claim.processClaim(pid);
    }

    function test_insufficientLiquidityReverts() public {
        vm.prank(bob);
        uint256 pid = policy.purchasePolicy(200_000e6, uint48(30 days), 1500e8, true);
        feed.setAnswer(1600e8);
        vm.expectRevert(ClaimProcessor.InsufficientLiquidity.selector);
        claim.processClaim(pid);
    }

    function test_treasuryOnlyTimelockWithdraws() public {
        vm.prank(alice);
        vault.deposit(1_000_000e6, alice);
        vm.prank(bob);
        policy.purchasePolicy(10_000e6, uint48(7 days), 1500e8, true);
        uint256 bal = collateral.balanceOf(address(treasury));
        vm.prank(alice);
        vm.expectRevert();
        treasury.withdrawERC20(address(collateral), alice, bal);
    }

    function test_govTokenMinterIsTimelock() public view {
        assertEq(govToken.minter(), address(timelock));
    }

    function test_poolFactoryCreate() public {
        PoolFactory f = new PoolFactory();
        address p = f.deployPoolCreate(address(collateral));
        assertEq(PolicyPool(p).asset(), address(collateral));
    }

    function test_poolFactoryCreate2Predict() public {
        PoolFactory f = new PoolFactory();
        bytes32 salt = keccak256("shieldfi");
        address predicted = f.predictPoolAddress(salt, 1, address(collateral));
        address p = f.deployPoolCreate2(salt, address(collateral));
        assertEq(p, predicted);
    }
}
