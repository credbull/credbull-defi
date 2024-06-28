//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";

import { Vault } from "@credbull/vault/Vault.sol";
import { MaxCapPlugin } from "@credbull/plugin/MaxCapPlugin.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleMaxCapVault } from "@test/test/vault/SimpleMaxCapVault.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract MaxCapPluginTest is Test {
    SimpleMaxCapVault private vault;

    Vault.VaultParams private vaultParams;
    MaxCapPlugin.MaxCapPluginParams private maxCapParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        ParamsFactory pf = new ParamsFactory(helperConfig.getNetworkConfig());
        vaultParams = pf.createVaultParams();
        maxCapParams = pf.createMaxCapPluginParams();

        vault = new SimpleMaxCapVault(vaultParams, maxCapParams);
        precision = 10 ** SimpleUSDC(address(vaultParams.asset)).decimals();

        SimpleUSDC(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__MaxCapVault__ShouldRevertDepositIfReachedMaxCap() public {
        uint256 aliceDepositAmount = 100 * precision;
        //Call internal deposit function
        deposit(alice, aliceDepositAmount);

        uint256 maxCap = vault.maxCap();

        // Edge case - when total deposited asset is exactly 1 million
        uint256 bobDepositAmount = maxCap - aliceDepositAmount;
        SimpleUSDC(address(vaultParams.asset)).mint(bob, bobDepositAmount);
        deposit(bob, bobDepositAmount);

        uint256 additionalDepositAmount = 1 * precision;
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), additionalDepositAmount);

        vm.expectRevert(MaxCapPlugin.CredbullVault__MaxCapReached.selector);
        vault.deposit(additionalDepositAmount, alice);
        vm.stopPrank();
    }

    function test__MaxCapVault__UpdateMaxCapValue() public {
        uint256 newValue = 100 * precision;
        uint256 currentValue = vault.maxCap();

        assertTrue(newValue != currentValue);

        vault.updateMaxCap(newValue);

        assertTrue(vault.maxCap() == newValue);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
