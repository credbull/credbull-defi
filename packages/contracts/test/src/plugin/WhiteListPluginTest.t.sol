//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";
import { HelperConfig } from "@script/HelperConfig.s.sol";

import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { Vault } from "@credbull/vault/Vault.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleWhiteListVault } from "@test/test/vault/SimpleWhiteListVault.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract WhiteListPluginTest is Test {
    SimpleWhiteListVault private vault;
    DeployVaultFactory private deployer;
    CredbullWhiteListProvider private whiteListProvider;

    Vault.VaultParams private vaultParams;
    WhiteListPlugin.WhiteListPluginParams private whiteListParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (,, whiteListProvider, helperConfig) = deployer.runTest();
        ParamsFactory pf = new ParamsFactory(helperConfig.getNetworkConfig());
        vaultParams = pf.createVaultParams();
        whiteListParams = pf.createWhiteListPluginParams();
        whiteListParams.whiteListProvider = address(whiteListProvider);

        vault = new SimpleWhiteListVault(vaultParams, whiteListParams);
        precision = 10 ** SimpleUSDC(address(vaultParams.asset)).decimals();

        address[] memory whiteListAddresses = new address[](2);
        whiteListAddresses[0] = alice;
        whiteListAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(whiteListProvider.owner());
        vault.WHITELIST_PROVIDER().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        SimpleUSDC(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__WhiteListVault__RevertDepositIfReceiverNotWhiteListed() public {
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(whiteListProvider.owner());
        vault.WHITELIST_PROVIDER().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        uint256 depositAmount = 1000 * precision;

        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), depositAmount);

        vm.expectRevert(
            abi.encodeWithSelector(WhiteListPlugin.CredbullVault__NotWhiteListed.selector, alice, depositAmount)
        );
        vault.deposit(depositAmount, alice);
        vm.stopPrank();
    }

    function test__WhiteListVault__ShouldSkipCheckIfDepositIsLessThanThreshold() public {
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        uint256 depositAmount = 100 * precision;
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), depositAmount);

        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), depositAmount);
    }

    function test__WhiteListVault__SucessfulDepositOnWhiteListVault() public {
        uint256 depositAmount = 1000 * precision;
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), depositAmount);

        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), depositAmount);
    }

    function test__WhiteListVault__ShouldNotRevertOnWhiteListModifier() public {
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(whiteListProvider.owner());
        vault.WHITELIST_PROVIDER().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        vault.toggleWhiteListCheck();

        deposit(alice, 10 * precision);
        assertEq(vault.balanceOf(alice), 10 * precision);
    }

    function test__WhiteListVault__ShouldToggleWhiteList() public {
        bool beforeToggle = vault.checkWhiteList();
        vault.toggleWhiteListCheck();
        bool afterToggle = vault.checkWhiteList();
        assertEq(afterToggle, !beforeToggle);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
