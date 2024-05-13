//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { MaturityVaultMock } from "../mocks/vaults/MaturityVaultMock.m.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MaturityVault } from "../../src/extensions/MaturityVault.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";

contract MaturityVaultTest is Test {
    MaturityVaultMock private vault;

    ICredbull.VaultParams private vaultParams;
    HelperConfig private helperConfig;
    uint256 private precision;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        vaultParams = new HelperVaultTest(helperConfig.getNetworkConfig()).createTestVaultParams();

        vault = new MaturityVaultMock(vaultParams);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__MaturityVault__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(address(vaultParams.asset)).mint(vaultParams.custodian, 1 * precision);
        uint256 finalBalance = MockStablecoin(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.startPrank(vaultParams.custodian);
        vaultParams.asset.approve(vaultParams.custodian, finalBalance);
        vaultParams.asset.transferFrom(vaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        vm.prank(vaultParams.operator);
        vault.mature();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = vaultParams.asset.balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild");
    }

    function test__MaturityVault__RevertOnWithdrawIfVaultNotMatured() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vm.warp(vaultParams.redemptionOpensAt);

        vm.expectRevert(MaturityVault.CredbullVault__NotMatured.selector);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__MaturityVault__NotEnoughBalanceToMatureVault() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        deposit(alice, depositAmount, true);
        uint256 finalBalance = depositAmount;

        // ---- Transfer assets to vault ---
        vm.startPrank(vaultParams.custodian);
        vaultParams.asset.approve(vaultParams.custodian, finalBalance);
        vaultParams.asset.transferFrom(vaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert it can't be matured yet ---
        vm.prank(vaultParams.operator);
        vm.expectRevert(MaturityVault.CredbullVault__NotEnoughBalanceToMature.selector);
        vault.mature();
    }

    function test__MaturityVault__ExpectedAssetOnMaturity() public {
        uint256 depositAmount = 10 * precision;
        deposit(alice, depositAmount, true);

        uint256 expectedAssetVaulue = ((depositAmount * (100 + vaultParams.promisedYield)) / 100);

        assertEq(vault.expectedAssetsOnMaturity(), expectedAssetVaulue);
    }

    function test__MaturityVault__ShouldNotRevertOnMaturityModifier() public {
        uint256 depositAmount = 10 * precision;
        uint256 shares = deposit(alice, depositAmount, true);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vault.toogleMaturityCheck(false);

        vault.redeem(shares, alice, alice);
        assertEq(vaultParams.asset.balanceOf(alice), INITIAL_BALANCE * precision);
        vm.stopPrank();
    }

    function test__MaturityVault__ShouldToggleMaturityCheck() public {
        bool beforeToggle = vault.checkMaturity();
        vault.toogleMaturityCheck(!beforeToggle);
        bool afterToggle = vault.checkMaturity();
        assertEq(afterToggle, !beforeToggle);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.depositOpensAt);
        }

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
