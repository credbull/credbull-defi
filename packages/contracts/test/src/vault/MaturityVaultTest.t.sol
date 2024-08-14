//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { MaturityVault } from "@credbull/vault/MaturityVault.sol";

import { DeployVaultsSupport } from "@script/DeployVaultsSupport.s.sol";
import { VaultsSupportConfig } from "@script/TomlConfig.s.sol";

import { SimpleMaturityVault } from "@test/test/vault/SimpleMaturityVault.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract MaturityVaultTest is Test, VaultsSupportConfig {
    DeployVaultsSupport private deployer;
    SimpleMaturityVault private vault;

    MaturityVault.MaturityVaultParams private params;
    uint256 private precision;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        deployer = new DeployVaultsSupport().skipDeployCheck();
        (ERC20 cbl, ERC20 usdc,) = deployer.run();
        params = new ParamsFactory(usdc, cbl).createMaturityVaultParams();
        vault = new SimpleMaturityVault(params);

        SimpleUSDC asset = SimpleUSDC(address(params.vault.asset));
        precision = 10 ** asset.decimals();
        asset.mint(alice, INITIAL_BALANCE * precision);
        asset.mint(bob, INITIAL_BALANCE * precision);
    }

    function test__MaturityVault__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        SimpleUSDC(address(params.vault.asset)).mint(params.vault.custodian, 1 * precision);
        uint256 finalBalance = SimpleUSDC(address(params.vault.asset)).balanceOf(params.vault.custodian);

        vm.startPrank(params.vault.custodian);
        params.vault.asset.approve(params.vault.custodian, finalBalance);
        params.vault.asset.transferFrom(params.vault.custodian, address(vault), finalBalance);
        vm.stopPrank();

        vm.expectEmit();
        emit MaturityVault.VaultMatured(finalBalance);
        vault.mature();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = params.vault.asset.balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = params.vault.asset.balanceOf(alice);
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

        // ---- Transfer fewer assets to vault (arbitrarily use half the assets) ---
        uint256 finalBalance = depositAmount / 2;
        vm.startPrank(params.vault.custodian);
        params.vault.asset.approve(params.vault.custodian, finalBalance);
        params.vault.asset.transferFrom(params.vault.custodian, address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert it can't be matured yet ---
        // vm.prank(params.roles.operator);
        vm.expectRevert(MaturityVault.CredbullVault__NotEnoughBalanceToMature.selector);
        vault.mature();
    }

    function test__MaturityVault__ExpectedAssetOnMaturity() public {
        uint256 depositAmount = 10 * precision;
        deposit(alice, depositAmount);

        uint256 expectedAssetValue = depositAmount;
        assertEq(vault.expectedAssetsOnMaturity(), expectedAssetValue);
    }

    function test__MaturityVault__ShouldNotRevertOnMaturityModifier() public {
        uint256 depositAmount = 10 * precision;
        uint256 shares = deposit(alice, depositAmount);

        vm.prank(params.vault.custodian);
        params.vault.asset.transfer(address(vault), depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vault.setMaturityCheck(!vault.checkMaturity());

        vault.redeem(shares, alice, alice);
        assertEq(params.vault.asset.balanceOf(alice), INITIAL_BALANCE * precision);
        vm.stopPrank();
    }

    function test__MaturityVault__ShouldSetMaturityCheck() public {
        bool beforeToggle = vault.checkMaturity();
        vault.setMaturityCheck(!beforeToggle);
        bool afterToggle = vault.checkMaturity();
        assertEq(afterToggle, !beforeToggle);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        params.vault.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
