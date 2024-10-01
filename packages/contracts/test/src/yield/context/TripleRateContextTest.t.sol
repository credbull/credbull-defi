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

        ITripleRateContext.TenorPeriodRate memory currentTenorPeriodRate = toTest.currentTenorPeriodRate();
        assertEq(
            EFFECTIVE_FROM_PERIOD, currentTenorPeriodRate.effectiveFromTenorPeriod, "Incorrect Current Tenor Period"
        );
        assertEq(PERCENT_5_5_SCALED, currentTenorPeriodRate.interestRate, "Incorrect Current Reduced Rate");

        ITripleRateContext.TenorPeriodRate memory previousTenorPeriodRate = toTest.previousTenorPeriodRate();
        assertEq(0, previousTenorPeriodRate.effectiveFromTenorPeriod, "Incorrect Previous Tenor Period");
        assertEq(0, previousTenorPeriodRate.interestRate, "Incorrect Previous Reduced Rate");
    }

    function test_TripleRateContext_SetCurrentTenorPeriodRateWorks() public {
        // Checked event emission.
        vm.expectEmit();
        emit TripleRateContext.CurrentTenorPeriodRateChanged(PERCENT_10_SCALED, 3);

        toTest.setReducedRateAt(3, PERCENT_10_SCALED);

        ITripleRateContext.TenorPeriodRate memory currentTenorPeriodRate = toTest.currentTenorPeriodRate();
        assertEq(3, currentTenorPeriodRate.effectiveFromTenorPeriod, "Incorrect Current Tenor Period");
        assertEq(PERCENT_10_SCALED, currentTenorPeriodRate.interestRate, "Incorrect Current Reduced Rate");

        ITripleRateContext.TenorPeriodRate memory previousTenorPeriodRate = toTest.previousTenorPeriodRate();
        assertEq(
            EFFECTIVE_FROM_PERIOD, previousTenorPeriodRate.effectiveFromTenorPeriod, "Incorrect Previous Tenor Period"
        );
        assertEq(PERCENT_5_5_SCALED, previousTenorPeriodRate.interestRate, "Incorrect Previous Reduced Rate");
    }

    function test_TripleRateContext_RevertSetCurrentTenorPeriodRate_WhenPeriodIsAtOrBeforeCurrent() public {
        // Before
        vm.expectRevert(
            abi.encodeWithSelector(TripleRateContext.TripleRateContext_TenorPeriodRegressionNotAllowed.selector, 0, 0)
        );
        toTest.setReducedRateAt(0, PERCENT_10_SCALED);

        toTest.setReducedRateAt(3, PERCENT_10_SCALED);
        // At
        vm.expectRevert(
            abi.encodeWithSelector(TripleRateContext.TripleRateContext_TenorPeriodRegressionNotAllowed.selector, 3, 3)
        );
        toTest.setReducedRateAt(3, PERCENT_5_SCALED);
    }
}
