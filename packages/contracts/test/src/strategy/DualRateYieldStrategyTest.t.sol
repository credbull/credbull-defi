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
        uint256 fullAPY = 10;
        uint256 reducedAPY = 5;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContextMock(fullAPY, reducedAPY, frequency, tenor, DECIMALS);
        address contextAddress = address(multiRateContext);

        uint256 principal = 500 * SCALE;
        uint256 depositPeriod = 1;

        // check tenor period
        assertApproxEqAbs(
            CalcSimpleInterest.calcInterest(principal, fullAPY, tenor, frequency),
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + tenor),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );

        // check outside tenor period
        uint256 partialPeriodDays = 20;
        assertApproxEqAbs(
            CalcSimpleInterest.calcInterest(principal, reducedAPY, partialPeriodDays, frequency),
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + partialPeriodDays),
            TOLERANCE,
            "yield wrong at partialTenor period"
        );
    }

    function test__MultiRateYieldStrategy__SuccessCriteria() public {
        uint256 fullAPY = 10;
        uint256 reducedAPY = 5;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_365);
        uint256 tenor = 30;

        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        DualRateContextMock dualRateContext = new DualRateContextMock(fullAPY, reducedAPY, frequency, tenor, DECIMALS);
        address contextAddress = address(dualRateContext);

        uint256 principal = 1000 * SCALE;
        uint256 depositPeriod = 1; // could be any day

        // Scenario: User deposits 1000 USDC and redeems the APY before maturity
        assertApproxEqAbs(
            2_054_794, // $1,000 * 0.5 * 15 / 365 =  2.0547945
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 15),
            TOLERANCE,
            "reducedAPY yield wrong at deposit + 15 days"
        );

        // Scenario: User deposits 1000 USDC and redeems the Principal before maturity
        assertApproxEqAbs(
            2_739_726, // $1,000 * 0.5 * 20 / 365 =  2.7397260
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 20),
            TOLERANCE,
            "reducedAPY yield wrong at deposit + 20 days"
        );

        // Scenario: User deposits 1000 USDC and redeems the APY after maturity
        // Scenario: User deposits 1000 USDC and redeems the Principal after maturity (covers 2 scenarios)
        assertApproxEqAbs(
            8_219_178, // $1,000 * 1.0 * 30 / 365 = 8.2191781
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + tenor),
            TOLERANCE,
            "fullyAPY yield wrong at deposit + TENOR days"
        );

        // Scenario: User tries to redeem the APY the same day they request redemption
        // TODO - reject redemption, implement with TimeLock or similar

        // Scenario: User tries to redeem the Principal the same day they request redemption
        // TODO - reject redemption, implement with TimeLock or similar

        // Scenario: User deposits 1000 USD, retains for extra cycle, redeems the APY before new cycle ends
        // And the T-Bill Rate for the second cycle is 5.5%
        // TODO lucasia - need to scale interest in code base
        // TODO lucasia - confirm with Pedro/Jehan fullRate rule.  is it > tenorPeriod or >= tenorPeriod
        dualRateContext.setReducedRate(6); // temp rule - with 6% before scaling interest rate
        assertApproxEqAbs(
            10_684_931, // Full[30]+Reduced[15] = 8.2191781 + ($1,000 * 0.6 * 15/365) = 8.2191781 + 2.4657534 = 10.6849315 // 6% reducedRate
            //          10_479_452, // Full[30]+Reduced[15] = 8.2191781 + ($1,000 * 0.55 * 15/365) = 8.2191781 + 2.2602740 = 10.4794521 // 5.5% reducedRate
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 45),
            TOLERANCE,
            "yield wrong at deposit + 45 days"
        );
    }
}

contract DualRateContextMock is CalcInterestMetadata, IDualRateContext {
    uint256 public reducedRatePercentage; // IR as %, e.g. 15 for 15% (or 0.15)
    uint256 public immutable TENOR;

    constructor(uint256 _fullRate, uint256 _reducedRatePercentage, uint256 _frequency, uint256 _tenor, uint256 decimals)
        CalcInterestMetadata(_fullRate, _frequency, decimals)
    {
        TENOR = _tenor;
        reducedRatePercentage = _reducedRatePercentage;
    }

    function fullRate() public view returns (uint256 rateInPercentage) {
        return INTEREST_RATE;
    }

    function reducedRate() public view returns (uint256 rateInPercentage) {
        return reducedRatePercentage;
    }

    function setReducedRate(uint256 _reducedRatePercentage) public {
        reducedRatePercentage = _reducedRatePercentage;
    }

    function periodsForFullRate() public view returns (uint256 numPeriods) {
        return TENOR;
    }
}
