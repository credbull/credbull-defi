// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";
import { DualRateYieldStrategy } from "@credbull/strategy/DualRateYieldStrategy.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";

import { IDualRateContext } from "@credbull/interest/IDualRateContext.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract DualRateYieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test__MultiRateYieldStrategy__CalculatYield() public {
        uint256 rateFullTenor = 10;
        uint256 ratePartialTenor = 5;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContextMock(rateFullTenor, ratePartialTenor, frequency, tenor);
        address contextAddress = address(multiRateContext);

        uint256 principal = 500 * SCALE;
        uint256 depositPeriod = 1;

        // check tenor period
        assertApproxEqAbs(
            CalcSimpleInterest.calcInterest(principal, rateFullTenor, tenor, frequency),
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + tenor),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );

        // check outside tenor period
        uint256 partialPeriodDays = 20;
        assertApproxEqAbs(
            CalcSimpleInterest.calcInterest(principal, ratePartialTenor, partialPeriodDays, frequency),
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + partialPeriodDays),
            TOLERANCE,
            "yield wrong at partialTenor period"
        );
    }
}

contract DualRateContextMock is CalcInterestMetadata, IDualRateContext {
    uint256 public immutable PARTIAL_TENOR_INTEREST_RATE; // IR as %, e.g. 15 for 15% (or 0.15)
    uint256 public immutable TENOR;

    constructor(uint256 _fullRate, uint256 _reducedRate, uint256 _frequency, uint256 _tenor)
        CalcInterestMetadata(_fullRate, _frequency, _reducedRate)
    {
        TENOR = _tenor;
        PARTIAL_TENOR_INTEREST_RATE = _reducedRate;
    }

    function fullRate() public view returns (uint256 rateInPercentage) {
        return INTEREST_RATE;
    }

    function reducedRate() public view returns (uint256 rateInPercentage) {
        return PARTIAL_TENOR_INTEREST_RATE;
    }

    function periodsForFullRate() public view returns (uint256 numPeriods) {
        return TENOR;
    }
}
