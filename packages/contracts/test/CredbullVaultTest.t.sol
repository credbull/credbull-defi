//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { MockStablecoin } from "./mocks/MockStablecoin.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { DeployVaultFactory } from "../script/DeployVaultFactory.s.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";

contract CredbullVaultTest is Test {
    CredbullVault private vault;
    CredbullVaultFactory factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;

    address private owner;
    address private custodian;
    address private asset;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private vaultOpenTime;

    uint256 private constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory, helperConfig) = deployer.runTest();

        vault = createTestVault();

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = alice;
        whitelistAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        CredbullVault.Rules memory rules =
            CredbullVault.Rules({ checkMaturity: true, checkVaultOpenStatus: true, checkWhitelist: true });

        vm.startPrank(owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vault.setRules(rules);
        vm.stopPrank();

        MockStablecoin(asset).mint(alice, INITIAL_BALANCE);
        MockStablecoin(asset).mint(bob, INITIAL_BALANCE);
    }

    function test__OwnerOfContract() public {
        assertEq(vault.owner(), owner);
    }

    function test__ShareNameAndSymbol() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        assertEq(vault.name(), config.vaultParams.shareName);
        assertEq(vault.symbol(), config.vaultParams.shareSymbol);
    }

    function test__CustodianAddress() public {
        assertEq(vault.custodian(), custodian);
    }

    function test__DepositAssetsAndGetShares() public {
        uint256 custodiansBalance = IERC20(asset).balanceOf(custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(IERC20(asset).balanceOf(address(vault)), 0, "Vault should start with no assets");
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
            IERC20(asset).balanceOf(custodian),
            depositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

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
        deposit(alice, depositAmount, true);
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
        uint256 shares = deposit(alice, depositAmount, true);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vm.expectRevert(CredbullVault.CredbullVault__NotMatured.selector);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__RevertDepositIfReceiverNotWhitelisted() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        vm.expectRevert(CredbullVault.CredbullVault__NotAWhitelistedAddress.selector);
        vm.warp(vaultOpenTime);
        vault.deposit(10 ether, alice);
    }

    function test__RevertDepositIfVaultNotOpened() public {
        vm.expectRevert(CredbullVault.CredbullVault__VaultNotOpened.selector);
        vault.deposit(10 ether, alice);
    }

    function test__ShouldNotRevertOnVaultOpenModifier() public {
        setRule(true, false, true);
        deposit(alice, 10 ether, false);
        assertEq(vault.balanceOf(alice), 10 ether);
    }

    function test__ShouldNotRevertOnWhitelistModifier() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        setRule(true, true, false);
        deposit(alice, 10 ether, true);
        assertEq(vault.balanceOf(alice), 10 ether);
    }

    function test__ShouldNotRevertOnMaturityModifier() public {
        setRule(false, true, true);

        uint256 depositAmount = 10 ether;
        uint256 shares = deposit(alice, depositAmount, true);

        vm.prank(custodian);
        IERC20(asset).transfer(address(vault), depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vault.redeem(shares, alice, alice);
        assertEq(IERC20(asset).balanceOf(alice), INITIAL_BALANCE);
        vm.stopPrank();
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        IERC20(asset).approve(address(vault), assets);

        // now we can deposit, alice is the caller and receiver
        if (warp) {
            vm.warp(vaultOpenTime);
        }

        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }

    function setRule(bool maturity, bool vaultOpen, bool whitelist)
        internal
        returns (CredbullVault.Rules memory rules)
    {
        rules =
            CredbullVault.Rules({ checkMaturity: maturity, checkVaultOpenStatus: vaultOpen, checkWhitelist: whitelist });

        vm.prank(owner);
        vault.setRules(rules);
    }

    function createTestVault() internal returns (CredbullVault) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        owner = params.owner;
        asset = address(params.asset);
        vaultOpenTime = params.openAt;
        custodian = params.custodian;
        vm.prank(owner);
        return factory.createVault(params);
    }
}
