// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DynamicDualRateContext } from "@credbull/interest/DynamicDualRateContext.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";
import { console2 as console } from "forge-std/console2.sol";

contract DynamicDualRateContextTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant FULL_RATE = PERCENT_10_SCALED;
    uint256 public constant REDUCED_RATE = PERCENT_5_SCALED;

    uint256 public constant TENOR = 30;

    uint256 public immutable FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

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

    function test_DynamicDualRateContext_ExpectedReducedRatesAreReturned() public {
        toTest = new DynamicDualRateContext(PERCENT_5_SCALED, PERCENT_5_5_SCALED, FREQUENCY, TENOR, DECIMALS);
        initialiseRates();

        // Term: 30, Periods: 4 -> 10
        uint256[][] memory expectedRates = new uint256[][](2);
        expectedRates[0] = REDUCED_RATES[0];
        expectedRates[1] = REDUCED_RATES[1];

        uint256[][] memory rates = toTest.reducedRatesFor(4, 10);
        assertEq(expectedRates.length, rates.length, "incorrect number of rates returned");
        for (uint256 i = 0; i < rates.length; i++) {
            assertEq(expectedRates[i], rates[i], "non-matching rates");
            console.log("Index= %d, Period= %d, Rate= %d", i, rates[i][0], rates[i][1]);
        }

        // Term: 30, Periods: 9 -> 32
        expectedRates = new uint256[][](3);
        expectedRates[0] = REDUCED_RATES[1];
        expectedRates[1] = REDUCED_RATES[2];
        expectedRates[2] = REDUCED_RATES[3];

        rates = toTest.reducedRatesFor(9, 32);
        assertEq(expectedRates.length, rates.length, "incorrect number of rates returned");
        for (uint256 i = 0; i < rates.length; i++) {
            assertEq(expectedRates[i], rates[i], "non-matching rates");
            console.log("Index= %d, Period= %d, Rate= %d", i, rates[i][0], rates[i][1]);
        }

        // Term: 30, Periods: 20 -> 61
        expectedRates = new uint256[][](6);
        expectedRates[0] = REDUCED_RATES[2];
        expectedRates[1] = REDUCED_RATES[3];
        expectedRates[2] = REDUCED_RATES[4];
        expectedRates[3] = REDUCED_RATES[5];
        expectedRates[4] = REDUCED_RATES[6];
        expectedRates[5] = REDUCED_RATES[7];

        rates = toTest.reducedRatesFor(20, 61);
        assertEq(expectedRates.length, rates.length, "incorrect number of rates returned");
        for (uint256 i = 0; i < rates.length; i++) {
            assertEq(expectedRates[i], rates[i], "non-matching rates");
            console.log("Index= %d, Period= %d, Rate= %d", i, rates[i][0], rates[i][1]);
        }
    }
}
