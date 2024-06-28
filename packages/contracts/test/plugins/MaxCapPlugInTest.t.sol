//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { MaxCapVaultMock } from "../mocks/vaults/MaxCapVaultMock.m.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MaxCapPlugIn } from "../../src/plugins/MaxCapPlugIn.sol";
import { CredbullBaseVault } from "./../../src/base/CredbullBaseVault.sol";

contract MaxCapPluginTest is Test {
    MaxCapVaultMock private vault;

    CredbullBaseVault.BaseVaultParams private vaultParams;
    MaxCapPlugIn.MaxCapParams private maxCapParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        vaultParams = new HelperVaultTest(helperConfig.getNetworkConfig()).createBaseVaultTestParams();
        maxCapParams = new HelperVaultTest(helperConfig.getNetworkConfig()).createMaxCapParams();

        vault = new MaxCapVaultMock(vaultParams, maxCapParams);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__MaxCapVault__ShouldRevertDepositIfReachedMaxCap() public {
        uint256 aliceDepositAmount = 100 * precision;
        //Call internal deposit function
        deposit(alice, aliceDepositAmount);

        uint256 maxCap = vault.maxCap();

        // Edge case - when total deposited asset is exactly 1 million
        uint256 bobDepositAmount = maxCap - aliceDepositAmount;
        MockStablecoin(address(vaultParams.asset)).mint(bob, bobDepositAmount);
        deposit(bob, bobDepositAmount);

        uint256 additionalDepositAmount = 1 * precision;
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), additionalDepositAmount);

        vm.expectRevert(MaxCapPlugIn.CredbullVault__MaxCapReached.selector);
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
