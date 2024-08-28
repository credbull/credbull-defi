// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "./ISimpleInterest.s.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { IERC4626Interest } from "./IERC4626Interest.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { InterestTest } from "./InterestTest.t.sol";
import { TimelockInterestVault } from "./TimelockInterestVault.s.sol";
import { ITimelock } from "@test/src/timelock/ITimelock.s.sol";

contract TimelockInterestVaultTest is InterestTest {
    IERC20 private asset;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    function setUp() public {
        uint256 tokenSupply = 100000 ether;

        vm.startPrank(owner);
        asset = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 10000 ether;

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, owner, alice, userTokenAmount);
        transferAndAssert(asset, owner, bob, userTokenAmount);
    }

    function test__TimelockInterestVaultTest__Daily() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, apy, frequencyValue, tenor);

        // check principal and interest calcs
        testInterestToMaxPeriods(200 * SCALE, vault);
    }

    function test__TimelockInterestVault__DepositAndRedeemFlow() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, apy, frequencyValue, tenor);

        uint256 depositAmount = 1000 ether;

        // Alice deposits tokens into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Assert that the shares were correctly minted
        assertEq(shares, vault.balanceOf(alice), "Incorrect number of shares minted to Alice");
        // Assert that the shares are correctly locked
        uint256 lockedAmount = vault.getLockedAmount(alice, vault.getCurrentTimePeriodsElapsed() + tenor);
        assertEq(lockedAmount, shares, "Shares were not correctly locked after deposit");

        vm.startPrank(alice);
        // when we redeem at time 0, currentlTimePeriod = unlockPeriod, so throws a shares not unlocked (rather than time lock) error.
        vm.expectRevert(abi.encodeWithSelector(ITimelock.InsufficientLockedBalance.selector, 0, depositAmount));
        vault.redeem(shares, alice, alice);
        vm.stopPrank();

        // Advance time to after the lock period
        vault.setCurrentTimePeriodsElapsed(tenor);

        // give the vault enough to cover the earned interest
        uint256 interest = vault.calcInterest(depositAmount, vault.getTenor());
        vm.startPrank(owner);
        transferAndAssert(asset, owner, address(vault), interest);
        vm.stopPrank();

        // Attempt to redeem after the lock period, should succeed
        vm.startPrank(alice);
        uint256 redeemedAssets = vault.redeem(shares, alice, alice);
        vm.stopPrank();

        // Assert that Alice received the correct amount of assets, including interest
        uint256 expectedAssets = depositAmount + vault.calcInterest(depositAmount, tenor);
        assertEq(redeemedAssets, expectedAssets, "Alice did not receive the correct amount of assets after redeeming");

        // Assert that Alice's share balance is now zero
        assertEq(vault.balanceOf(alice), 0, "Alice's share balance should be zero after redeeming");
    }

    function testInterestAtPeriod(uint256 principal, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        internal
        override
    {
        // test against the simple interest harness
        super.testInterestAtPeriod(principal, simpleInterest, numTimePeriods);

        // test the vault related
        IERC4626Interest vault = (IERC4626Interest)(address(simpleInterest));
        super.testConvertToAssetAndSharesAtPeriod(principal, vault, numTimePeriods); // previews only
        super.testDepositAndRedeemAtPeriod(owner, alice, principal, vault, numTimePeriods); // actual deposits/redeems
    }
}
