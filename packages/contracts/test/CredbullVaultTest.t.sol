//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { DeployVault } from "../script/DeployVault.s.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { MockStablecoin } from "./mocks/MockStablecoin.sol";

contract CredbullVaultTest is Test {
    CredbullVault private vault;
    DeployVault private deployer;
    HelperConfig private config;

    address private owner;
    address private custodian;
    address private asset;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        deployer = new DeployVault();
        (CredbullVault[] memory _vaults, HelperConfig _config) = deployer.run();
        vault = _vaults[0];
        config = _config;

        (owner, asset,,, custodian,,) = config.activeNetworkConfig();

        MockStablecoin(asset).mint(alice, INITIAL_BALANCE);
        MockStablecoin(asset).mint(bob, INITIAL_BALANCE);
    }

    function test__OwnerOfContract() public {
        assertEq(vault.owner(), owner);
    }

    function test__ShareNameAndSymbol() public {
        (,, string memory shareName, string memory shareSymbol,,,) = config.activeNetworkConfig();
        assertEq(vault.name(), shareName);
        assertEq(vault.symbol(), shareSymbol);
    }

    function test__CustodianAddress() public {
        assertEq(vault.custodian(), custodian);
    }

    function test__DepositAssetsAndGetShares() public {
        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(IERC20(asset).balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - Alice Deposit and Receives shares ----
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ---- Assert - Vault gets the Assets, Alice gets Shares ----

        // Vault should have the assets
        assertEq(vault.totalAssets(), depositAmount, "Vault should now have the assets");
        assertEq(IERC20(asset).balanceOf(custodian), depositAmount, "Custodian should have received the assets");

        // Alice should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(asset).mint(custodian, 1 ether);
        uint256 finalBalance = MockStablecoin(asset).balanceOf(custodian);

        vm.startPrank(custodian);
        IERC20(asset).approve(address(custodian), finalBalance);
        IERC20(asset).transferFrom(custodian, address(vault), finalBalance);
        vm.stopPrank();

        vm.prank(owner);
        vault.mature();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = IERC20(asset).balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = IERC20(asset).balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild");
    }

    function test_NotEnoughBalanceToMatureVault() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        deposit(alice, depositAmount);
        uint256 finalBalance = depositAmount;

        // ---- Transfer assets to vault ---
        vm.startPrank(custodian);
        IERC20(asset).approve(address(custodian), finalBalance);
        IERC20(asset).transferFrom(custodian, address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert it can't be matured yet ---
        vm.prank(owner);
        vm.expectRevert(CredbullVault.CredbullVault__NotEnoughBalanceToMature.selector);
        vault.mature();
    }

    function test__RevertOnWithdrawIfVaultNotMatured() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vm.expectRevert(CredbullVault.CredbullVault__NotMatured.selector);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        IERC20(asset).approve(address(vault), assets);

        // now we can deposit, alice is the caller and receiver
        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }
}
