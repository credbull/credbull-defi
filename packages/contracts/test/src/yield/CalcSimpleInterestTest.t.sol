// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract CalcSimpleInterestTest is Test {
    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

    uint256 public constant SCALE = 10 ** 6;

    function test__CalcInterestTest__Daily() public pure {
        uint256 apy = 12 * SCALE;
        uint256 tenor = 30;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        uint256 principal = 2000 * SCALE;

        CalcSimpleInterest.InterestParams memory paramsDay0 = CalcSimpleInterest.InterestParams({
            numTimePeriodsElapsed: 0,
            interestRatePercentScaled: apy,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            scale: SCALE
        });

        // interest should be equal for these assertions
        uint256 interestDay0 = CalcSimpleInterest.calcInterest(principal, paramsDay0);
        assertEq(0, interestDay0, "interest should be 0 at day 0");

        uint256 interestDay3 = CalcSimpleInterest.calcInterest(principal, InterestParamsBuilder.build(3, paramsDay0));
        assertEq(2 * SCALE, interestDay3, "interest should be 2 at day 3");

        uint256 interestDay30 =
            CalcSimpleInterest.calcInterest(principal, InterestParamsBuilder.build(tenor, paramsDay0));
        assertEq(20 * SCALE, interestDay30, "interest should be 20 at day 30");

        // interest should be *almost* equal for below assertions
        uint256 interestDay1 = CalcSimpleInterest.calcInterest(principal, InterestParamsBuilder.build(1, paramsDay0));
        assertEq(666_666, interestDay1, "interest should be ~ 0.6666 at day 1");

        uint256 interestDay2 = CalcSimpleInterest.calcInterest(principal, InterestParamsBuilder.build(2, paramsDay0));
        assertEq(1_333_333, interestDay2, "interest should be ~ 1.3333 at day 2");

        uint256 interestDay29 = CalcSimpleInterest.calcInterest(principal, InterestParamsBuilder.build(29, paramsDay0));
        assertEq(19_333_333, interestDay29, "interest should be ~ 19.3333 at day 29");

        assertEq(
            480_666_666,
            CalcSimpleInterest.calcInterest(principal, InterestParamsBuilder.build(721, paramsDay0)),
            "interest should be ~ 480.6666 at day 721"
        );
        assertEq(
            480_666_666,
            CalcSimpleInterest.calcInterest(principal, apy, 721, frequency, SCALE),
            "interest should be ~ 480.6666 at day 721"
        );
    }

    function test__CalcInterestTest_CalculatePrice() public pure {
        uint256 apy = 12 * SCALE;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        assertEq(1 * SCALE, CalcSimpleInterest.calcPriceFromInterest(apy, 0, frequency, SCALE)); // 1 + (0.12 * 0) / 360 = 1
        assertEq(1_000_333, CalcSimpleInterest.calcPriceFromInterest(apy, 1, frequency, SCALE)); // 1 + (0.12 * 1) / 360 ≈ 1.00033
        assertEq((101 * SCALE / 100), CalcSimpleInterest.calcPriceFromInterest(apy, 30, frequency, SCALE)); // 1 + (0.12 * 30) / 360 = 1.01
    }
}

library InterestParamsBuilder {
    function build(uint256 numTimePeriodsElapsed, CalcSimpleInterest.InterestParams memory baseParams)
        internal
        pure
        returns (CalcSimpleInterest.InterestParams memory newParams)
    {
        return CalcSimpleInterest.InterestParams({
            interestRatePercentScaled: baseParams.interestRatePercentScaled,
            numTimePeriodsElapsed: numTimePeriodsElapsed,
            frequency: baseParams.frequency,
            scale: baseParams.scale
        });
    }
}
