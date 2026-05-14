// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ShieldFiBase} from "../base/ShieldFiBase.sol";
import {InsuranceVault} from "../../contracts/vault/InsuranceVault.sol";
import {MockERC20} from "../../contracts/mocks/MockERC20.sol";

contract VaultHandler is Test {
    InsuranceVault public immutable v;
    MockERC20 public immutable a;
    address public immutable actor;

    uint256 public ghostDeposited;
    uint256 public ghostWithdrawn;

    constructor(InsuranceVault vault_, MockERC20 asset_) {
        v = vault_;
        a = asset_;
        actor = address(0xC0FFEE);
        a.mint(actor, 1e24);
        vm.startPrank(actor);
        a.approve(address(v), type(uint256).max);
        vm.stopPrank();
    }

    function deposit(uint256 assets) public {
        assets = bound(assets, 1, 5_000_000e6);
        vm.startPrank(actor);
        v.deposit(assets, actor);
        vm.stopPrank();
        ghostDeposited += assets;
    }

    function withdraw(uint256 sharePortionBps) public {
        uint256 shares = v.balanceOf(actor);
        if (shares == 0) return;
        sharePortionBps = bound(sharePortionBps, 1, 10_000);
        uint256 burn = (shares * sharePortionBps) / 10_000;
        if (burn == 0) return;
        vm.startPrank(actor);
        uint256 assets = v.redeem(burn, actor, actor);
        vm.stopPrank();
        ghostWithdrawn += assets;
    }
}

contract VaultInvariantTest is ShieldFiBase {
    VaultHandler internal handler;

    function setUp() public override {
        super.setUp();
        handler = new VaultHandler(vault, collateral);
        targetContract(address(handler));
    }

    function invariant_vaultSolvent() public view {
        assertGe(IERC20(collateral).balanceOf(address(vault)), 0);
    }

    function invariant_totalSupplyBounded() public view {
        assertLe(vault.totalSupply(), type(uint128).max);
    }

    function invariant_actorSharesLteTotalSupply() public view {
        assertLe(vault.balanceOf(handler.actor()), vault.totalSupply());
    }

    function invariant_sharePriceSane() public view {
        uint256 ts = vault.totalSupply();
        if (ts == 0) return;
        assertGe(vault.totalAssets(), vault.convertToAssets(1));
    }

    function invariant_treasuryAccounting() public view {
        assertGe(collateral.balanceOf(address(treasury)), 0);
    }
}
