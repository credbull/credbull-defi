//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";
import { HelperConfig } from "@script/HelperConfig.s.sol";

import { CredbullKYCProvider } from "@src/CredbullKYCProvider.sol";
import { Vault } from "@src/vault/Vault.sol";
import { WhitelistPlugIn } from "@src/plugin/WhitelistPlugIn.sol";
import { WindowPlugIn } from "@src/plugin/WindowPlugIn.sol";

import { MockStablecoin } from "@test/test/mock/MockStablecoin.t.sol";
import { MockWhitelistVault } from "@test/test/mock/vault/MockWhitelistVault.t.sol";
import { MockWindowVault } from "@test/test/mock/vault/MockWindowVault.t.sol";
import { ParametersFactory } from "@test/test/vault/ParametersFactory.t.sol";

contract WhitelistPlugInTest is Test {
    MockWhitelistVault private vault;
    DeployVaultFactory private deployer;
    CredbullKYCProvider private kycProvider;

    Vault.VaultParameters private vaultParams;
    WhitelistPlugIn.WhitelistPlugInParameters private whitelistParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (,, kycProvider, helperConfig) = deployer.runTest();
        ParametersFactory pf = new ParametersFactory(helperConfig.getNetworkConfig());
        vaultParams = pf.createVaultParameters();
        whitelistParams = pf.createWhitelistPlugInParameters();
        whitelistParams.kycProvider = address(kycProvider);

        vault = new MockWhitelistVault(vaultParams, whitelistParams);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = alice;
        whitelistAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(kycProvider.owner());
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

        vm.startPrank(kycProvider.owner());
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        uint256 depositAmount = 1000 * precision;

        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), depositAmount);

        vm.expectRevert(
            abi.encodeWithSelector(WhitelistPlugIn.CredbullVault__NotAWhitelistedAddress.selector, alice, depositAmount)
        );
        vault.deposit(depositAmount, alice);
        vm.stopPrank();
    }

    function test__WhitelistVault__ShouldSkipCheckIfDepositIsLessThanThreshold() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        uint256 depositAmount = 100 * precision;
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), depositAmount);

        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(vault.balanceOf(alice), depositAmount);
    }

    function test__WhitelistVault__SucessfulDepositOnWhitelistVault() public {
        uint256 depositAmount = 1000 * precision;
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

        vm.startPrank(kycProvider.owner());
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        vault.toggleWhitelistCheck(false);

        deposit(alice, 10 * precision);
        assertEq(vault.balanceOf(alice), 10 * precision);
    }

    function test__WhitelistVault__ShouldToggleWhitelist() public {
        bool beforeToggle = vault.checkWhitelist();
        vault.toggleWhitelistCheck(!beforeToggle);
        bool afterToggle = vault.checkWhitelist();
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
