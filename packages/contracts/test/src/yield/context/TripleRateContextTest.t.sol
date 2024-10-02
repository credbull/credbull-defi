// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { TestTripleRateContext } from "@test/test/yield/context/TestTripleRateContext.t.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract TripleRateContextTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant EFFECTIVE_FROM_PERIOD = 0;
    uint256 public constant TENOR = 30;

    uint256 public immutable FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    TripleRateContext internal toTest;

    function setUp() public {
        toTest = new TestTripleRateContext(
            PERCENT_5_SCALED, PERCENT_5_5_SCALED, EFFECTIVE_FROM_PERIOD, FREQUENCY, TENOR, DECIMALS
        );
    }

    function test_TripleRateContext_ConstructedAsExpected() public view {
        assertEq(PERCENT_5_SCALED, toTest.rateScaled(), "Incorrect Full Rate");
        assertEq(TENOR, toTest.numPeriodsForFullRate(), "Incorrect No Of Period For Full Rate");

        ITripleRateContext.PeriodRate memory currentPeriodRate = toTest.currentPeriodRate();
        assertEq(EFFECTIVE_FROM_PERIOD, currentPeriodRate.effectiveFromPeriod, "Incorrect Current Period");
        assertEq(PERCENT_5_5_SCALED, currentPeriodRate.interestRate, "Incorrect Current Reduced Rate");

        ITripleRateContext.PeriodRate memory previousPeriodRate = toTest.previousPeriodRate();
        assertEq(0, previousPeriodRate.effectiveFromPeriod, "Incorrect Previous Period");
        assertEq(0, previousPeriodRate.interestRate, "Incorrect Previous Reduced Rate");
    }

    function test_TripleRateContext_SetCurrentPeriodRateWorks() public {
        // Checked event emission.
        vm.expectEmit();
        emit TripleRateContext.CurrentPeriodRateChanged(PERCENT_10_SCALED, 3);

        toTest.setReducedRate(PERCENT_10_SCALED, 3);

        ITripleRateContext.PeriodRate memory currentPeriodRate = toTest.currentPeriodRate();
        assertEq(3, currentPeriodRate.effectiveFromPeriod, "Incorrect Current Period");
        assertEq(PERCENT_10_SCALED, currentPeriodRate.interestRate, "Incorrect Current Reduced Rate");

        ITripleRateContext.PeriodRate memory previousPeriodRate = toTest.previousPeriodRate();
        assertEq(EFFECTIVE_FROM_PERIOD, previousPeriodRate.effectiveFromPeriod, "Incorrect Previous Period");
        assertEq(PERCENT_5_5_SCALED, previousPeriodRate.interestRate, "Incorrect Previous Reduced Rate");
    }

    function test_TripleRateContext_RevertSetCurrentPeriodRate_WhenPeriodIsAtOrBeforeCurrent() public {
        // Before
        vm.expectRevert(
            abi.encodeWithSelector(TripleRateContext.TripleRateContext_PeriodRegressionNotAllowed.selector, 0, 0)
        );
        toTest.setReducedRate(PERCENT_10_SCALED, 0);

        toTest.setReducedRate(PERCENT_10_SCALED, 3);
        // At
        vm.expectRevert(
            abi.encodeWithSelector(TripleRateContext.TripleRateContext_PeriodRegressionNotAllowed.selector, 3, 3)
        );
        toTest.setReducedRate(PERCENT_5_SCALED, 3);
    }
}
