//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployStakingVaults } from "@script/DeployStakingVaults.s.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";

import { CBL } from "@credbull/token/CBL.sol";

contract CredbullFixedYieldVaultStakingTest is Test {
    CredbullFixedYieldVault private vault;
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
        (, vault, helperConfig) = deployStakingVaults.run();

        cbl = CBL(vault.asset());
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
        assertTrue(vault.checkWindow(), "window should be on");

        vm.prank(owner);
        vault.toggleWindowCheck();
        assertFalse(vault.checkWindow(), "window should be off");

        uint256 depositAmount = 10 * precision;
        uint256 shares = deposit(vault, alice, depositAmount, false);

        assertEq(depositAmount, cbl.balanceOf(vault.CUSTODIAN()), "custodian should have the CBL");
        assertEq(shares, vault.balanceOf(alice), "alice should have the shares");

        uint256 expectedAssetValue = ((depositAmount * (100 + 50)) / 100);
        assertEq(vault.expectedAssetsOnMaturity(), expectedAssetValue);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        return deposit(vault, user, assets, warp);
    }

    function deposit(CredbullFixedYieldVault fixedYieldVault, address user, uint256 assets, bool warp)
        internal
        returns (uint256 shares)
    {
        // first, approve the deposit
        vm.startPrank(user);
        cbl.approve(address(fixedYieldVault), assets);

        // wrap if set to true
        if (warp) {
            vm.warp(fixedYieldVault.depositOpensAtTimestamp());
        }

        shares = fixedYieldVault.deposit(assets, user);
        vm.stopPrank();
    }
}
