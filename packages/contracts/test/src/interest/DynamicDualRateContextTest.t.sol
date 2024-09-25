// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DynamicDualRateContext } from "@credbull/interest/DynamicDualRateContext.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract DynamicDualRateContextTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant TENOR = 30;

    uint256 public immutable FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    uint256[][] public DEFAULT_REDUCED_RATES = [[1, PERCENT_5_5_SCALED]];

    uint256[][] public REDUCED_RATES = [
        [2, scaled(25) / 10], // 2.5%
        [9, scaled(58) / 10], // 5.8%
        [17, scaled(61) / 10], // 6.1%
        [22, PERCENT_5_SCALED], // 5%
        [34, scaled(52) / 10], // 34%
        [41, scaled(41) / 10], // 4.1%
        [49, scaled(5)], // 5%
        [55, PERCENT_5_5_SCALED], // 5.5%
        [63, scaled(59) / 10] // 5.9%
    ];

    DynamicDualRateContext internal toTest;

    function scaled(uint256 toScale) private pure returns (uint256) {
        return toScale * SCALE;
    }

    function initialiseRates() private {
        for (uint256 i = 0; i < REDUCED_RATES.length; i++) {
            toTest.setReducedRate(REDUCED_RATES[i][0], REDUCED_RATES[i][1]);
        }
    }

    function setUp() public {
        toTest = new DynamicDualRateContext(PERCENT_5_SCALED, PERCENT_5_5_SCALED, FREQUENCY, TENOR, DECIMALS);
        initialiseRates();
    }

    function test_DynamicDualRateContext_AttributesAsExpected() public view {
        assertEq(PERCENT_5_5_SCALED, toTest.DEFAULT_REDUCED_RATE(), "Incorrect Reduced Rate");
        assertEq(PERCENT_5_SCALED, toTest.fullRateScaled(), "Incorrect Full Rate");
        assertEq(TENOR, toTest.numPeriodsForFullRate(), "Incorrect No Of Period For Full Rate");
    }

    function test_DynamicDualRateContext_RevertWhenFromAndToSame() public {
        vm.expectRevert(
            abi.encodeWithSelector(DynamicDualRateContext.DynamicDualRateContext_InvalidPeriodRange.selector, 3, 3)
        );
        toTest.reducedRatesFor(3, 3);
    }

    function test_DynamicDualRateContext_RevertWhenToBeforeFrom() public {
        vm.expectRevert(
            abi.encodeWithSelector(DynamicDualRateContext.DynamicDualRateContext_InvalidPeriodRange.selector, 4, 1)
        );
        toTest.reducedRatesFor(4, 1);
    }

    function test_DynamicDualRateContext_DefaultRateWhenUnconfigured() public {
        toTest = new DynamicDualRateContext(PERCENT_5_SCALED, PERCENT_5_5_SCALED, FREQUENCY, TENOR, DECIMALS);

        // Periods: 1 -> 12
        uint256[][] memory expectedRates = DEFAULT_REDUCED_RATES;
        uint256[][] memory actualRates = toTest.reducedRatesFor(1, 12);
        assertRates(expectedRates, actualRates, "Incorrect Rates for Range 1->12, Unconfigured");
    }

    function test_DynamicDualRateContext_CorrectRatesReturned() public view {
        // Periods: 4 -> 10
        uint256[][] memory expectedRates = new uint256[][](2);
        expectedRates[0] = REDUCED_RATES[0];
        expectedRates[1] = REDUCED_RATES[1];

        uint256[][] memory actualRates = toTest.reducedRatesFor(4, 10);
        assertRates(expectedRates, actualRates, "Incorrect Rates for Range 4->10, Correct");

        // Periods: 9 -> 32
        expectedRates = new uint256[][](3);
        expectedRates[0] = REDUCED_RATES[1];
        expectedRates[1] = REDUCED_RATES[2];
        expectedRates[2] = REDUCED_RATES[3];

        actualRates = toTest.reducedRatesFor(9, 32);
        assertRates(expectedRates, actualRates, "Incorrect Rates for Range 9->32, Correct");

        // Periods: 20 -> 61
        expectedRates = new uint256[][](6);
        expectedRates[0] = REDUCED_RATES[2];
        expectedRates[1] = REDUCED_RATES[3];
        expectedRates[2] = REDUCED_RATES[4];
        expectedRates[3] = REDUCED_RATES[5];
        expectedRates[4] = REDUCED_RATES[6];
        expectedRates[5] = REDUCED_RATES[7];

        actualRates = toTest.reducedRatesFor(20, 61);
        assertRates(expectedRates, actualRates, "Incorrect Rates for Range 20->61, Correct");
    }

    function assertRates(uint256[][] memory expected, uint256[][] memory actual, string memory error) public pure {
        assertEq(expected.length, actual.length, "incorrect number of rates returned");
        for (uint256 i = 0; i < actual.length; i++) {
            assertEq(expected[i], actual[i], error);
        }
    }
}