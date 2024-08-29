// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "@test/interfaces/ISimpleInterest.s.sol";
import { SimpleToken } from "@test/token/SimpleToken.t.sol";

import { IERC4626Interest } from "../interfaces/IERC4626Interest.s.sol";
import { Frequencies } from "@test/fixed/Frequencies.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { InterestTest } from "@test/fixed/InterestTest.t.sol";
import { TimelockInterestVault } from "@test/fixed/TimelockInterestVault.s.sol";
import { ITimelock } from "@test/interfaces/ITimelock.s.sol";

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

        // ------------- deposit ---------------
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Assert that the shares were correctly minted
        assertEq(shares, vault.balanceOf(alice), "Incorrect number of shares minted to Alice");
        // Assert that the shares are correctly locked
        uint256 lockedAmount = vault.getLockedAmount(alice, vault.getCurrentTimePeriodsElapsed() + tenor);
        assertEq(shares, lockedAmount, "Shares were not correctly locked after deposit");

        // ------------- redeem (before tenor / maturity time period) ---------------

        vm.startPrank(alice);
        // when we redeem at time 0, currentlTimePeriod = unlockPeriod, so throws a shares not unlocked (rather than time lock) error.
        vm.expectRevert(abi.encodeWithSelector(ITimelock.InsufficientLockedBalance.selector, 0, depositAmount));
        vault.redeem(shares, alice, alice); // try to redeem before warping - should fail
        vm.stopPrank();

        // ------------- redeem (at tenor / maturity time period) ---------------
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
        assertEq(expectedAssets, redeemedAssets, "Alice did not receive the correct amount of assets after redeeming");

        // Assert that Alice's share balance is now zero
        assertEq(0, vault.balanceOf(alice), "Alice's share balance should be zero after redeeming");
    }

    function test__TimelockInterestVault__FullRolloverOfShares() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, apy, frequencyValue, tenor);

        uint256 depositAmount = 1000 ether;

        // ------------- deposit ---------------
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // ------------- advance time to allow unlock ---------------
        uint256 periodOneEnd = tenor;
        vault.setCurrentTimePeriodsElapsed(periodOneEnd);
        // Assert that the shares are now unlockable
        uint256 unlockableAmount = vault.previewUnlock(alice, periodOneEnd);
        assertEq(shares, unlockableAmount, "All shares should be unlockable after the lock period");

        // ------------- rollover the shares ---------------

        // vault needs permission from alice to adjust shares on the ERC4626 side for the rollover.
        uint256 expectedSharesNextPeriod =
            vault.calcDiscounted(depositAmount + vault.calcInterest(depositAmount, tenor), tenor); // discounted rate of first period's principal + interest
        uint256 actualSharesNextPeriod = vault.previewConvertSharesForRollover(alice, periodOneEnd, shares);
        assertEq(expectedSharesNextPeriod, actualSharesNextPeriod, "shares next period incorrect");
        vm.startPrank(alice);
        vault.approve(owner, depositAmount - actualSharesNextPeriod); // give the vault ability to transfer excess shares on my behalf
        vm.stopPrank();

        vm.startPrank(owner);
        vault.rolloverUnlocked(alice, vault.getCurrentTimePeriodsElapsed(), shares);
        vm.stopPrank();

        uint256 periodTwoEnd = vault.getCurrentTimePeriodsElapsed() + tenor; // Roll over to another 30-day period

        // Assert that the shares are now locked under the new rollover period
        assertEq(actualSharesNextPeriod, vault.balanceOf(alice), "Incorrect vault shares after full rollover");

        // Assert that the original lock period has no remaining shares
        assertEq(
            0,
            vault.getLockedAmount(alice, tenor),
            "Original lock period should have no remaining shares after rollover"
        );
        assertEq(
            actualSharesNextPeriod,
            vault.getLockedAmount(alice, tenor + tenor),
            "New lock period should have no remaining shares after rollover"
        );

        // ------------- redeem (after new rollover period) ---------------
        vault.setCurrentTimePeriodsElapsed(periodTwoEnd); // Advance time to the new rollover period

        // give the vault enough to cover the earned interest for the rollover period
        uint256 interest = 3 * vault.calcInterest(depositAmount, tenor); // a little more than two periods interest
        vm.startPrank(owner);
        transferAndAssert(asset, owner, address(vault), interest);
        vm.stopPrank();

        // Attempt to redeem after the rollover lock period, should succeed
        vm.startPrank(alice);
        uint256 actualRedeemedAssets = vault.redeem(actualSharesNextPeriod, alice, alice);
        vm.stopPrank();

        // Assert that Alice's share balance is now zero
        assertEq(0, vault.balanceOf(alice), "Alice's share balance should be zero after redeeming");

        // Assert that Alice received the correct amount of assets, including interest
        uint256 expectedInterestPeriod1 = vault.calcInterest(depositAmount, tenor);
        uint256 expectedInterestPeriod2 = vault.calcInterest(depositAmount + expectedInterestPeriod1, tenor); // compound the 2nd interest

        uint256 expectedRedeemAssets = depositAmount + expectedInterestPeriod1 + expectedInterestPeriod2;
        assertEq(
            expectedRedeemAssets,
            actualRedeemedAssets,
            "Alice did not receive the correct amount of assets after redeeming"
        );
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
