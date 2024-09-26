// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITripleRateContext } from "@credbull/interest/context/ITripleRateContext.sol";
import { TripleRateContext } from "@credbull/interest/context/TripleRateContext.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract TripleRateContextTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant TENOR = 30;

    uint256 public immutable FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    TripleRateContext internal toTest;

    function setUp() public {
        toTest = new TripleRateContext(PERCENT_5_SCALED, PERCENT_5_5_SCALED, FREQUENCY, TENOR, DECIMALS);
    }

    function test_TripleRateContext_ConstructedAsExpected() public view {
        assertEq(PERCENT_5_SCALED, toTest.rateScaled(), "Incorrect Full Rate");
        assertEq(TENOR, toTest.numPeriodsForFullRate(), "Incorrect No Of Period For Full Rate");

        (uint256 currentTenorPeriod, uint256 currentReducedRate) = toTest.currentTenorPeriodAndRate();
        assertEq(1, currentTenorPeriod, "Incorrect Current Tenor Period");
        assertEq(PERCENT_5_5_SCALED, currentReducedRate, "Incorrect Current Reduced Rate");

        (uint256 previousTenorPeriod, uint256 previousReducedRate) = toTest.previousTenorPeriodAndRate();
        assertEq(0, previousTenorPeriod, "Incorrect Previous Tenor Period");
        assertEq(0, previousReducedRate, "Incorrect Previous Reduced Rate");
    }

    function test_TripleRateContext_SetCurrentTenorPeriodRateWorks() public {
        // Checked event emission.
        vm.expectEmit();
        emit TripleRateContext.CurrentTenorPeriodAndRateChanged(3, PERCENT_10_SCALED);

        toTest.setReducedRateAt(3, PERCENT_10_SCALED);

        (uint256 currentTenorPeriod, uint256 currentReducedRate) = toTest.currentTenorPeriodAndRate();
        assertEq(3, currentTenorPeriod, "Incorrect Current Tenor Period");
        assertEq(PERCENT_10_SCALED, currentReducedRate, "Incorrect Current Reduced Rate");

        (uint256 previousTenorPeriod, uint256 previousReducedRate) = toTest.previousTenorPeriodAndRate();
        assertEq(1, previousTenorPeriod, "Incorrect Previous Tenor Period");
        assertEq(PERCENT_5_5_SCALED, previousReducedRate, "Incorrect Previous Reduced Rate");
    }

    function test_TripleRateContext_RevertSetCurrentTenorPeriodRate_WhenPeriodIsAtOrBeforeCurrent() public {
        // Before
        vm.expectRevert(
            abi.encodeWithSelector(TripleRateContext.TripleRateContext_TenorPeriodRegressionNotAllowed.selector, 1, 0)
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
