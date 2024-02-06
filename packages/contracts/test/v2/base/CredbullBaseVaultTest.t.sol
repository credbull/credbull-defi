//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullBaseVaultMock } from "../../mocks/vaults/CredbullBaseVaultMock.m.sol";
import { ICredbull } from "../../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig } from "../../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../../mocks/MockStablecoin.sol";

contract CredbullBaseVaultTest is Test {
    CredbullBaseVaultMock private vault;
    HelperConfig private helperConfig;

    ICredbull.VaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vault = new CredbullBaseVaultMock(vaultParams);

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE);
    }

    function test__BaseVault__ShareNameAndSymbol() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        assertEq(vault.name(), config.vaultParams.shareName);
        assertEq(vault.symbol(), config.vaultParams.shareSymbol);
    }

    function test__BaseVault__CustodianAddress() public {
        assertEq(vault.custodian(), vaultParams.custodian);
    }

    function test__BaseVault__DepositAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - Alice Deposit and Receives shares ----
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ---- Assert - Vault gets the Assets, Alice gets Shares ----

        // Vault should have the assets
        assertEq(vault.totalAssets(), depositAmount, "Vault should now have the assets");
        assertEq(
            vaultParams.asset.balanceOf(vaultParams.custodian),
            depositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__BaseVault__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(address(vaultParams.asset)).mint(vaultParams.custodian, 1 ether);
        uint256 finalBalance = MockStablecoin(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.startPrank(vaultParams.custodian);
        vaultParams.asset.approve(vaultParams.custodian, finalBalance);
        vaultParams.asset.transferFrom(vaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = vaultParams.asset.balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild");
    }

    function test__BaseVault__totalAssetShouldReturnTotalDeposited() public {
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        deposit(alice, depositAmount, true);

        assertEq(vault.totalAssets(), vault.totalAssetDeposited());
        assertEq(vault.totalAssetDeposited(), depositAmount);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.depositOpensAt);
        }

        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }
}
