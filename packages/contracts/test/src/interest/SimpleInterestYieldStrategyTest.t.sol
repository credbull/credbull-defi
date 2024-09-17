// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterestYieldStrategy } from "@credbull/interest/SimpleInterestYieldStrategy.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract FixedYielStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test__FixedYielStrategyTest__CalculatePrice() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        SimpleInterestYieldStrategy yieldStrategy = new SimpleInterestYieldStrategyMock(apy, frequency, DECIMALS);

        assertEq(1 * SCALE, yieldStrategy.calcPrice(0), "price wrong at period 0"); // 1 + (0.12 * 0) / 360 = 1
        assertEq(1_000_333, yieldStrategy.calcPrice(1), "price wrong at period 1"); // 1 + (0.12 * 1) / 360 ≈ 1.00033
        assertEq((101 * SCALE / 100), yieldStrategy.calcPrice(30), "price wrong at period 30"); // 1 + (0.12 * 30) / 360 = 1.01
    }

    function test__FixedYielStrategyTest__CalculatYield() public {
        uint256 apy = 6; // APY in percentage
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        SimpleInterestYieldStrategy yieldStrategy = new SimpleInterestYieldStrategyMock(apy, frequency, DECIMALS);

        uint256 principal = 500 * SCALE;

        assertApproxEqAbs(83_333, yieldStrategy.calcYield(principal, 0, 1), TOLERANCE, "yield wrong at period 0 to 1");
        assertApproxEqAbs(166_666, yieldStrategy.calcYield(principal, 1, 3), TOLERANCE, "yield wrong at period 1 to 3");
        assertApproxEqAbs(
            2_500_000, yieldStrategy.calcYield(principal, 1, 31), TOLERANCE, "yield wrong at period 1 to 31"
        );
    }
}

contract SimpleInterestYieldStrategyMock is SimpleInterestYieldStrategy, CalcInterestMetadata {
    constructor(uint256 interestRatePercentage, uint256 frequency, uint256 decimals)
        CalcInterestMetadata(interestRatePercentage, frequency, decimals)
    { }

    function getFrequency()
        public
        view
        override(SimpleInterestYieldStrategy, CalcInterestMetadata)
        returns (uint256 frequency)
    {
        return CalcInterestMetadata.getFrequency();
    }

    function getInterestInPercentage()
        public
        view
        override(SimpleInterestYieldStrategy, CalcInterestMetadata)
        returns (uint256 interestRateInPercentage)
    {
        return CalcInterestMetadata.getInterestInPercentage();
    }

    function getScale()
        public
        view
        override(SimpleInterestYieldStrategy, CalcInterestMetadata)
        returns (uint256 scale)
    {
        return CalcInterestMetadata.getScale();
    }
}
