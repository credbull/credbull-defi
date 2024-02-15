//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullBaseVaultMock } from "../mocks/vaults/CredbullBaseVaultMock.m.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { CredbullBaseVault } from "../../src/base/CredbullBaseVault.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { MockToken } from "../mocks/MockToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import { console2 } from "forge-std/console2.sol";

contract CredbullBaseVaultTest is Test {
    using Math for uint256;

    CredbullBaseVaultMock private vault;
    HelperConfig private helperConfig;

    ICredbull.VaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vault = new CredbullBaseVaultMock(vaultParams);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
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
        uint256 depositAmount = 10 * precision;
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
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        deposit(alice, depositAmount, true);

        assertEq(vault.totalAssets(), vault.totalAssetDeposited());
        assertEq(vault.totalAssetDeposited(), depositAmount);
    }

    function test__BaseVault__ShouldRevertOnTransferOutsideEcosystem() public {
        uint256 depositAmount = 100 * precision;
        deposit(alice, depositAmount, true);

        vm.prank(alice);
        vm.expectRevert(CredbullBaseVault.CredbullVault__TransferOutsideEcosystem.selector);
        vault.transfer(bob, 100 * precision);
    }

    function test__BaseVault__ShouldRevertOnFractionalDepositAmount_Fuzz(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1, 1e6 * 1e6);

        if ((depositAmount % precision) > 0) {
            vm.startPrank(alice);
            vaultParams.asset.approve(address(vault), depositAmount);
            vm.expectRevert(CredbullBaseVault.CredbullVault__InvalidAssetAmount.selector);
            vm.warp(vaultParams.depositOpensAt);
            vault.deposit(depositAmount, alice);
            vm.stopPrank();
        } else {
            deposit(alice, depositAmount, true);
        }
    }

    function test__ShouldRevertIfDecimalIsNotSupported() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vm.expectRevert(CredbullBaseVault.CredbullVault__UnsupportedDecimalValue.selector);
        vm.mockCall(address(vaultParams.asset), abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(24));
        new CredbullBaseVaultMock(vaultParams);
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
