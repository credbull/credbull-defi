//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { MaturityVaultMock } from "../mocks/vaults/MaturityVaultMock.m.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MaturityVault } from "../../src/extensions/MaturityVault.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { FixedYieldVault } from "../../src/vaults/FixedYieldVault.sol";

contract MaturityVaultTest is Test {
    MaturityVaultMock private vault;

    MaturityVault.MaturityVaultParams private params;
    HelperConfig private helperConfig;
    uint256 private precision;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        params = new HelperVaultTest(helperConfig.getNetworkConfig()).createMaturityVaultTestParams();

        vault = new MaturityVaultMock(params);
        precision = 10 ** MockStablecoin(address(params.baseVaultParams.asset)).decimals();

        MockStablecoin(address(params.baseVaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockStablecoin(address(params.baseVaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__MaturityVault__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(address(params.baseVaultParams.asset)).mint(params.baseVaultParams.custodian, 1 * precision);
        uint256 finalBalance =
            MockStablecoin(address(params.baseVaultParams.asset)).balanceOf(params.baseVaultParams.custodian);

        vm.startPrank(params.baseVaultParams.custodian);
        params.baseVaultParams.asset.approve(params.baseVaultParams.custodian, finalBalance);
        params.baseVaultParams.asset.transferFrom(params.baseVaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        vault.mature();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = params.baseVaultParams.asset.balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = params.baseVaultParams.asset.balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild");
    }

    function test__MaturityVault__RevertOnWithdrawIfVaultNotMatured() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vm.expectRevert(MaturityVault.CredbullVault__NotMatured.selector);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__MaturityVault__NotEnoughBalanceToMatureVault() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        deposit(alice, depositAmount);
        uint256 finalBalance = depositAmount;

        // ---- Transfer assets to vault ---
        vm.startPrank(params.baseVaultParams.custodian);
        params.baseVaultParams.asset.approve(params.baseVaultParams.custodian, finalBalance);
        params.baseVaultParams.asset.transferFrom(params.baseVaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert it can't be matured yet ---
        // vm.prank(params.contractRoles.operator);
        vm.expectRevert(MaturityVault.CredbullVault__NotEnoughBalanceToMature.selector);
        vault.mature();
    }

    function test__MaturityVault__ExpectedAssetOnMaturity() public {
        uint256 depositAmount = 10 * precision;
        deposit(alice, depositAmount);

        uint256 expectedAssetVaulue = ((depositAmount * (100 + params.promisedYield)) / 100);

        assertEq(vault.expectedAssetsOnMaturity(), expectedAssetVaulue);
    }

    function test__MaturityVault__ShouldNotRevertOnMaturityModifier() public {
        uint256 depositAmount = 10 * precision;
        uint256 shares = deposit(alice, depositAmount);

        vm.prank(params.baseVaultParams.custodian);
        params.baseVaultParams.asset.transfer(address(vault), depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vault.toogleMaturityCheck(false);

        vault.redeem(shares, alice, alice);
        assertEq(params.baseVaultParams.asset.balanceOf(alice), INITIAL_BALANCE * precision);
        vm.stopPrank();
    }

    function test__MaturityVault__ShouldToggleMaturityCheck() public {
        bool beforeToggle = vault.checkMaturity();
        vault.toogleMaturityCheck(!beforeToggle);
        bool afterToggle = vault.checkMaturity();
        assertEq(afterToggle, !beforeToggle);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        params.baseVaultParams.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
