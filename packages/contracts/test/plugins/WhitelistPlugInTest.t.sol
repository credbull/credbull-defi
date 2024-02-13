//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { WhitelistVaultMock } from "../mocks/vaults/WhitelistVaultMock.m.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { WhitelistPlugIn } from "../../src/plugins/WhitelistPlugIn.sol";

contract WhitelistPlugInTest is Test {
    WhitelistVaultMock private vault;

    ICredbull.VaultParams private vaultParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    uint256 precision;

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vault = new WhitelistVaultMock(vaultParams);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = alice;
        whitelistAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__WhitelistVault__RevertDepositIfReceiverNotWhitelisted() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        vm.expectRevert(WhitelistPlugIn.CredbullVault__NotAWhitelistedAddress.selector);
        vault.deposit(10 * precision, alice);
    }

    function test__WhitelistVault__SucessfulDepositOnWhitelistVault() public {
        uint256 depositAmount = 10 * precision;
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), depositAmount);

        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), depositAmount);
    }

    function test__WhitelistVault__ShouldNotRevertOnWhitelistModifier() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        vault.toggleWhitelistCheck(false);

        deposit(alice, 10 * precision, true);
        assertEq(vault.balanceOf(alice), 10 * precision);
    }

    function test__WhitelistVault__ShouldToggleWhitelist() public {
        bool beforeToggle = vault.checkWhitelist();
        vault.toggleWhitelistCheck(!beforeToggle);
        bool afterToggle = vault.checkWhitelist();
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

        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }
}
