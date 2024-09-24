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
        uint256 fullRate = 10 * SCALE;
        uint256 reducedRate = 55 * SCALE / 10; // 5.5%
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContextMock(fullRate, reducedRate, frequency, tenor, DECIMALS);
        address contextAddress = address(multiRateContext);

        uint256 principal = 500 * SCALE;
        uint256 depositPeriod = 1;

        // check tenor period
        assertApproxEqAbs(
            CalcSimpleInterest.calcInterest(principal, fullRate, tenor, frequency, SCALE),
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + tenor),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );

        // check outside tenor period
        uint256 partialPeriodDays = 20;
        assertApproxEqAbs(
            CalcSimpleInterest.calcInterest(principal, reducedRate, partialPeriodDays, frequency, SCALE),
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + partialPeriodDays),
            TOLERANCE,
            "yield wrong at partialTenor period"
        );
    }

    function test__MultiRateYieldStrategy__SingleUserScenarios() public {
        uint256 fullRate = 10 * SCALE;
        uint256 reducedRateTenor1 = 5 * SCALE;
        uint256 reducedRateTenor2 = 55 * SCALE / 10;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_365);
        uint256 tenor = 30;

        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        DualRateContextMock dualRateContext =
            new DualRateContextMock(fullRate, reducedRateTenor1, frequency, tenor, DECIMALS);
        address contextAddress = address(dualRateContext);

        uint256 principal = 1000 * SCALE;
        uint256 depositPeriod = 1; // pick a day, any day.  assertions below should all still hold for any day.

        // Scenario S1: User deposits 1000 USDC and redeems the APY before maturity
        assertApproxEqAbs(
            2_054_794, // $1,000 * 0.5 * 15 / 365 =  2.054794
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 15),
            TOLERANCE,
            "reducedAPY yield wrong at deposit + 15 days"
        );

        // Scenario S2: User deposits 1000 USDC and redeems the Principal before maturity
        assertApproxEqAbs(
            2_739_726, // $1,000 * 0.5 * 20 / 365 =  2.739726
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 20),
            TOLERANCE,
            "reducedAPY yield wrong at deposit + 20 days"
        );

        // Scenario S3: User deposits 1000 USDC and redeems the APY after maturity
        assertApproxEqAbs(
            8_219_178, // $1,000 * 1.0 * 30 / 365 = 8.219178
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + tenor),
            TOLERANCE,
            "fullyAPY yield wrong at deposit + TENOR days"
        );

        // TODO MultiToken Scenario S4: User deposits 1000 USDC and redeems the Principal after maturity

        // Scenario S7: User deposits 1000 USD, retains for extra cycle, redeems the APY before new cycle ends
        dualRateContext.setReducedRate(reducedRateTenor2);
        assertApproxEqAbs(
            10_479_452, // Full[30]+Reduced[15] = 8.2191781 + ($1,000 * 0.55 * 15/365) = 8.2191781 + 2.2602740 = 10.479452 // 5.5% reducedRate
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 45),
            TOLERANCE,
            "yield wrong at deposit + 45 days"
        );

        // Scenario S8: User deposits 1000 USD, retains for extra cycle, redeems the Principal before new cycle ends
        assertApproxEqAbs(
            11_232_876, // Full[30]+Reduced[20] = 8.2191781 + ($1,000 * 0.55 * 20/365) = 8.2191781 + 3.0136986 = 11.232876 // 5.5% reducedRate
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 50),
            TOLERANCE,
            "yield wrong at deposit + 50 days"
        );

        // Scenario S9: User deposits 1000 USD, retains for extra cycle, redeems the APY after new cycle ends
        assertApproxEqAbs(
            16_438_356, // $1,000 * 1.0 * 60 / 365 = 16.438356
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + (2 * tenor)),
            TOLERANCE,
            "yield wrong at deposit + 2x tenor"
        );

        // TODO MultiToken Scenario S10: User deposits 1000 USD, retains for extra cycle, redeems the Principal after new cycle ends
    }

    function test__MultiRateYieldStrategy__MultipleUserScenarios() public {
        uint256 fullRate = 10 * SCALE;
        uint256 reducedRateTenor1 = 5 * SCALE;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_365);
        uint256 tenor = 30;

        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        DualRateContextMock dualRateContext =
            new DualRateContextMock(fullRate, reducedRateTenor1, frequency, tenor, DECIMALS);
        address contextAddress = address(dualRateContext);

        uint256 principal = 1000 * SCALE;

        uint256 depositPeriodUserA = 0; // TODO: confirm if this should be 0 or 1
        uint256 depositPeriodUserB = 15;

        // Scenario MU-1: Two users deposit at different funding rounds, both redeem at day 30 (day 1 and day 15)
        assertApproxEqAbs(
            8_219_178, // $1,000 * 1.0 * 29 / 365 = ???
            yieldStrategy.calcYield(contextAddress, principal, depositPeriodUserA, tenor),
            TOLERANCE,
            "reducedAPY yield wrong at deposit + tenor"
        );

        assertApproxEqAbs(
            2_054_794, // $1,000 * 0.5 * 15 / 365 =  2.054794
            yieldStrategy.calcYield(contextAddress, principal, depositPeriodUserB, tenor),
            TOLERANCE,
            "reducedAPY yield wrong at deposit + 15 days"
        );

        // TODO DualYieldStrategy: Scenario MU-2: Two users deposit at different funding rounds, both redeem 15 days after day 30 (day 1 and day 15)

        // TODO DualYieldStrategy: Scenario MU-3: Two users deposit at different funding round, with different T-Bill Rates, both redeem 14 days after day 30 (day 1 and day 15)
    }
}

contract DualRateContextMock is CalcInterestMetadata, IDualRateContext {
    uint256 public reducedRateInPercentageScaled;
    uint256 public immutable TENOR;

    constructor(
        uint256 fullRateInPercentageScaled_,
        uint256 reducedRateInPercentageScaled_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals
    ) CalcInterestMetadata(fullRateInPercentageScaled_, frequency_, decimals) {
        TENOR = tenor_;
        reducedRateInPercentageScaled = reducedRateInPercentageScaled_;
    }

    function fullRateScaled() public view returns (uint256 fullRateInPercentageScaled_) {
        return RATE_PERCENT_SCALED;
    }

    function reducedRateScaled() public view returns (uint256 reducedRateInPercentageScaled_) {
        return reducedRateInPercentageScaled;
    }

    function setReducedRate(uint256 reducedRateInPercentageScaled_) public {
        reducedRateInPercentageScaled = reducedRateInPercentageScaled_;
    }

    function numPeriodsForFullRate() public view returns (uint256 numPeriods) {
        return TENOR;
    }
}
