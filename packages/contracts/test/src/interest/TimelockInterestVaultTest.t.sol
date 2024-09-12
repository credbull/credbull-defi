// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { DiscountVaultTestBase } from "./DiscountVaultTestBase.t.sol";
import { TimelockInterestVault } from "@credbull/interest/TimelockInterestVault.sol";
import { ITimelock } from "@credbull/timelock/ITimelock.sol";

import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract TimelockInterestVaultTest is DiscountVaultTestBase {
    IERC20Metadata private asset;

    uint256 private constant TENOR_30 = 30;
    uint256 private constant APY_6 = 6;
    uint256 private constant APY_12 = 12;
    uint256 private constant FREQUENCY_360 = 360;

    uint256 internal SCALE;

    function setUp() public {
        uint256 tokenSupply = 1_000_000 ether; // USDC uses 6 decimals, so this is way more than 1m USDC

        vm.prank(owner);
        asset = new SimpleUSDC(tokenSupply);

        SCALE = 10 ** asset.decimals();

        uint256 userTokenAmount = 50_000 * SCALE;

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, owner, alice, userTokenAmount);
        transferAndAssert(asset, owner, bob, userTokenAmount);
    }

    function test__TimelockInterestVaultTest__Daily() public {
        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, APY_12, FREQUENCY_360, TENOR_30);

        // check principal and interest calcs
        testVaultAtTenorPeriods(200 * SCALE, vault);
    }

    // Scenario: User withdraws after the lock period
    function test__TimelockInterestVault__Deposit_Redeem() public {
        uint256 tenor = TENOR_30;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, APY_6, FREQUENCY_360, TENOR_30);

        uint256 depositAmount = 15_000 * SCALE;

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

        vm.prank(alice);
        // when we redeem at time 0, currentlTimePeriod = unlockPeriod, so throws a shares not unlocked (rather than time lock) error.
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.InsufficientLockedBalanceAtPeriod.selector,
                alice,
                0,
                shares,
                vault.getCurrentTimePeriodsElapsed()
            )
        );
        vault.redeem(shares, alice, alice); // try to redeem before warping - should fail

        // ------------- redeem (at tenor / maturity time period) ---------------
        vault.setCurrentTimePeriodsElapsed(tenor);

        // give the vault enough to cover the earned interest
        vm.prank(owner);
        transferAndAssert(asset, owner, address(vault), vault.calcYield(depositAmount, vault.getTenor()));

        // Attempt to redeem after the lock period, should succeed
        vm.prank(alice);
        uint256 redeemedAssets = vault.redeem(shares, alice, alice);

        // Assert that Alice received the correct amount of assets, including interest
        uint256 expectedAssets = depositAmount + vault.calcYield(depositAmount, tenor);
        assertEq(expectedAssets, redeemedAssets, "Alice did not receive the correct amount of assets after redeeming");
        assertEq(15_075 * SCALE, redeemedAssets, "Alice should receive $15,075 ($15,000 principal + $75 interest) back");

        // Assert that Alice's share balance is now zero
        assertEq(0, vault.balanceOf(alice), "Alice's share balance should be zero after redeeming");
    }

    function test__TimelockInterestVault__Rollover_1APY_Bonus() public {
        uint256 tenor = TENOR_30;
        uint256 depositAmount = 40_000 * SCALE;

        // setup
        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, APY_6, FREQUENCY_360, TENOR_30);
        vm.prank(owner);
        transferAndAssert(asset, owner, address(vault), 3 * vault.calcYield(depositAmount, tenor)); // give the vault enough to cover returns

        // ----------------------------------------------------------
        // ------------        Start Period 1          --------------
        // ----------------------------------------------------------

        // ------------- deposit ---------------
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 actualSharesPeriodOne = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // ------------- verify shares start of period 1 ---------------
        assertEq(depositAmount, actualSharesPeriodOne, "shares start of Period 1 incorrect");

        // ----------------------------------------------------------
        // ------------ End Period 1  (Start Period 2) --------------
        // ----------------------------------------------------------

        uint256 endPeriodOne = tenor;
        vault.setCurrentTimePeriodsElapsed(endPeriodOne); // warp to end of period 1

        // ------------- verify assets end of period 1 ---------------
        assertEq(
            actualSharesPeriodOne,
            vault.previewUnlock(alice, endPeriodOne),
            "full amount should be unlockable at end of period 1"
        );
        uint256 actualAssetsPeriodOne = vault.convertToAssets(actualSharesPeriodOne);
        assertEq(40_200 * SCALE, actualAssetsPeriodOne, "assets end of Period 1 incorrect"); // Principal[P1] + Interest[P1] = $40,000 + $200 = $40,200
        assertEq(
            33 * SCALE + (50 * SCALE) / 100,
            vault.calcRolloverBonus(alice, tenor, actualAssetsPeriodOne),
            "rollover bonus end of Period 1 incorrect"
        ); // Rollover Bonus =  ($40,200 * 0.1 * 30 / 360) = $33.50

        // ------------- verify shares start of period 2 ---------------
        // RolloverBonus: Principal(WithBonus)[P2] = Principal[P1] + Interest[P1] + RolloverBonus[P1] = $40,000 + $200 + $33.50 = $40,233.50
        // RolloverBonus: Discounted[P2] = Principal(WithBonus)[P2] / Price[P2] = $40,233.50 / (1 * 0.6 * 30 / 360) = $40,233.50 / $1.005 = $40,033.33
        uint256 expectedSharesPeriodTwo = 40_033 * SCALE + (333_333 * SCALE) / 1_000_000;
        assertEq(
            expectedSharesPeriodTwo,
            vault.previewConvertSharesForRollover(alice, endPeriodOne, actualSharesPeriodOne),
            "preview rollover shares start of Period 2 incorrect"
        );

        // ------------- rollover from period 1 to period 2 ---------------
        vm.startPrank(owner);
        vault.rolloverUnlocked(alice, vault.getCurrentTimePeriodsElapsed(), actualSharesPeriodOne);
        vm.stopPrank();

        // ------------- verify rollover of shares and locks ---------------
        uint256 actualSharesPeriodTwo = vault.balanceOf(alice);
        assertEq(
            expectedSharesPeriodTwo,
            actualSharesPeriodTwo,
            "alice should have Discounted[P2] worth of shares for Period 2"
        );
        assertEq(
            expectedSharesPeriodTwo,
            vault.getLockedAmount(alice, endPeriodOne + tenor),
            "all shares should be locked until end of Period 2"
        );
        assertEq(0, vault.getLockedAmount(alice, endPeriodOne), "no locks should remain on Period 1");

        // ----------------------------------------------------------
        // -------------         End Period 2         ---------------
        // ----------------------------------------------------------

        uint256 endPeriodTwo = endPeriodOne + tenor;
        vault.setCurrentTimePeriodsElapsed(endPeriodTwo); // warp to end of period 2

        // ------------- verify assets end of period 2---------------
        uint256 expectedAssetsPeriodTwo = 40_434 * SCALE + (6675 * SCALE) / 10_000; // Principal(WithBonus)[P2] + Interest(WithBonus)[P2] = $40,233.50 + $201.1675 = $40,434.6675 // with bonus credited day 30
        assertEq(
            actualSharesPeriodTwo,
            vault.previewUnlock(alice, endPeriodTwo),
            "full amount should be unlockable at end of period 2"
        );
        assertApproxEqAbs(
            expectedAssetsPeriodTwo,
            vault.convertToAssets(actualSharesPeriodTwo),
            TOLERANCE,
            "assets end of Period 2 incorrect"
        );

        // ------------- redeem at end of period 2 ---------------
        vm.prank(alice);
        uint256 actualRedeemedAssets = vault.redeem(actualSharesPeriodTwo, alice, alice);

        // ------------- verify assets after redeeming ---------------
        assertApproxEqAbs(
            expectedAssetsPeriodTwo,
            actualRedeemedAssets,
            TOLERANCE,
            "incorrect assets returned after after fully redeeming"
        );
        assertEq(0, vault.balanceOf(alice), "no shares should remain after fully redeeming");
        assertEq(0, vault.getLockedAmount(alice, endPeriodTwo), "no locks should remain after fully redeeming");
    }

    function test__TimelockInterestVault__PauseAndUnPause() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, apy, frequencyValue, tenor);

        uint256 depositAmount = 1000 * SCALE;

        // ------------- pause ---------------
        vm.prank(owner);
        vault.pause();
        assertTrue(vault.paused(), "vault should be paused");

        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector); // deposit when paused - fail
        vault.deposit(depositAmount, alice);

        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector); // redeem when paused - fail
        vault.redeem(depositAmount, alice, alice);

        // ------------- unpause ---------------
        vm.prank(owner);
        vault.unpause();
        assertFalse(vault.paused(), "vault should be unpaused");

        // unpaused deposit
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice); // deposit when unpaused - succeed
        vm.stopPrank();

        // unpaused redeem
        vault.setCurrentTimePeriodsElapsed(tenor); // warp to redeem time
        vm.prank(owner);
        transferAndAssert(asset, owner, address(vault), depositAmount); // cover the yield on the vault

        vm.prank(alice);
        vault.redeem(shares, alice, alice); // redeem when unpaused - succeed
    }

    // Scenario: User withdraws after the lock period
    function test__TimelockInterestVault__Early_Redeem_Should_Fail() public {
        uint256 tenor = TENOR_30;
        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, APY_6, FREQUENCY_360, tenor);

        uint256 depositAmount = 20_000 * SCALE;
        uint256 depositPeriod = tenor + 10;

        // ------------- deposit ---------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod);

        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // ------------- early redeem - before vault's first tenor  ---------------
        uint256 tenorMinus1 = tenor - 1;
        vault.setCurrentTimePeriodsElapsed(tenorMinus1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.InsufficientLockedBalanceAtPeriod.selector,
                alice,
                0,
                shares,
                vault.getCurrentTimePeriodsElapsed()
            )
        );
        vault.redeem(shares, alice, alice); // try to redeem before warping - should fail

        //    // ------------- early redeem - before deposit + redeem  ---------------
        uint256 redeemMinus1 = depositPeriod + tenor - 1;
        vault.setCurrentTimePeriodsElapsed(redeemMinus1);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.InsufficientLockedBalanceAtPeriod.selector,
                alice,
                0,
                shares,
                vault.getCurrentTimePeriodsElapsed()
            )
        );
        vault.redeem(shares, alice, alice);
    }

    function test__TimelockInterestVault__MultipleDeposits() public {
        uint256 tenor = TENOR_30;
        uint256 depositAmount1 = 10_000 * SCALE;
        uint256 depositAmount2 = 15_000 * SCALE;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, APY_6, FREQUENCY_360, tenor);

        // deposit
        uint256 depositPeriod1 = 5;
        vault.setCurrentTimePeriodsElapsed(depositPeriod1);
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount1);
        vault.deposit(depositAmount1, alice);
        vm.stopPrank();

        // another deposit
        uint256 depositPeriod2 = 10;
        vault.setCurrentTimePeriodsElapsed(depositPeriod2);
        vm.startPrank(alice);
        asset.approve(address(vault), depositAmount2);
        vault.deposit(depositAmount2, alice);
        vm.stopPrank();

        // warp to a future period
        uint256 verifyPeriod = tenor - 1;
        vault.setCurrentTimePeriodsElapsed(verifyPeriod);

        // check total deposits
        uint256 totalDeposit = vault.calcTotalDeposits(alice);
        uint256 expectedTotalDeposit = depositAmount1 + depositAmount2;
        assertApproxEqAbs(totalDeposit, expectedTotalDeposit, TOLERANCE, "incorrect total user deposit");

        // check the total interest
        uint256 totalInterest = vault.calcTotalInterest(alice);
        uint256 expectedInterest = vault.calcYield(depositAmount1, verifyPeriod - depositPeriod1)
            + vault.calcYield(depositAmount2, verifyPeriod - depositPeriod2);
        assertApproxEqAbs(totalInterest, expectedInterest, TOLERANCE, "incorrect total interest earned");
    }
}