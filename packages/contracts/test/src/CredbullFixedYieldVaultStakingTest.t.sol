//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployStakingVaults } from "@script/DeployStakingVaults.s.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";

import { CBL } from "@credbull/token/CBL.sol";

contract CredbullFixedYieldVaultStakingTest is Test {
    CredbullFixedYieldVault private vault50APY;
    CredbullFixedYieldVault private vault0APY;
    HelperConfig private helperConfig;

    CBL private cbl;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    address private owner;
    address private operator;
    address private minter;

    uint256 private precision;
    uint256 private constant INITIAL_BALANCE = 1000;

    function setUp() public {
        DeployStakingVaults deployStakingVaults = new DeployStakingVaults();
        (, vault50APY, vault0APY, helperConfig) = deployStakingVaults.run();

        cbl = CBL(vault50APY.asset());
        precision = 10 ** cbl.decimals();

        assertEq(10 ** 18, precision, "should be 10^18");

        owner = helperConfig.getNetworkConfig().factoryParams.owner;
        operator = helperConfig.getNetworkConfig().factoryParams.operator;
        minter = helperConfig.getNetworkConfig().factoryParams.operator;

        vm.startPrank(minter);
        cbl.mint(alice, INITIAL_BALANCE * precision);
        cbl.mint(bob, INITIAL_BALANCE * precision);
        vm.stopPrank();

        assertEq(INITIAL_BALANCE * precision, cbl.balanceOf(alice), "alice didn't receive CBL");
    }

    function test__FixedYieldVaultStakingChallenge__Expect50APY() public {
        uint256 depositAmount = 10 * precision;
        uint256 expectedAssets = ((depositAmount * (100 + 50)) / 100);

        depositAndVerify(vault50APY, depositAmount, expectedAssets);
    }

    function test__FixedYieldVaultStakingChallenge__Expect0APY() public {
        uint256 depositAmount = 10 * precision;

        depositAndVerify(vault0APY, depositAmount, depositAmount);
    }

    function depositAndVerify(CredbullFixedYieldVault vault, uint256 depositAmount, uint256 expectedAssets) public {
        assertTrue(vault.checkWindow(), "window should be on");

        vm.prank(owner);
        vault.toggleWindowCheck();
        assertFalse(vault.checkWindow(), "window should be off");

        vm.startPrank(alice);
        cbl.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(depositAmount, cbl.balanceOf(vault.CUSTODIAN()), "custodian should have the CBL");
        assertEq(shares, vault.balanceOf(alice), "alice should have the shares");

        assertEq(vault.expectedAssetsOnMaturity(), expectedAssets);
    }
}
