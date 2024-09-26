// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

import { MultipleRateYieldStrategy } from "@test/test/strategy/MultipleRateYieldStrategy.t.sol";
import { MultipleRateContext } from "@test/test/interest/context/MultipleRateContext.t.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract MultipleRateYieldStrategyScenarioTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant DEFAULT_FULL_RATE = PERCENT_10_SCALED;
    uint256 public constant DEFAULT_REDUCED_RATE = PERCENT_5_SCALED;

    uint256 public constant MATURITY_PERIOD = 30;

    uint256 public immutable DEFAULT_FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    IYieldStrategy internal yieldStrategy;
    MultipleRateContext internal context;
    address internal contextAddress;
    uint256 internal principal;
    uint256 internal depositPeriod;

    function setUp() public {
        yieldStrategy = new MultipleRateYieldStrategy();
        context = new MultipleRateContext(
            DEFAULT_FULL_RATE,
            DEFAULT_REDUCED_RATE,
            Frequencies.toValue(Frequencies.Frequency.DAYS_365),
            MATURITY_PERIOD,
            DECIMALS
        );
        contextAddress = address(context);
        principal = 1_000 * SCALE;
        depositPeriod = 1;
    }

    /**
     * S1
     * Scenario: User deposits 1000 USDC and redeems the APY before maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5%
     *  When the user requests to redeem the APY after 15 days
     *  Then the user should receive the prorated yield (2.055 USDC)
     *  And the principal should remain in the vault
     */
    function test_MultipleRateYieldStrategyScenario_S1() public view {
        assertEq(
            2_054_794, // $1,000 * ((5% / 365) * 15) =  2.054794
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 15),
            "reduced rate yield wrong at deposit + 15 days"
        );
    }

    /**
     * S2
     * Scenario: User deposits 1000 USDC and redeems the Principal before maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5%
     *  When the user requests to redeem the Principal after 20 days
     *  Then the user should receive their principal of 1000 USDC
     *  And the prorated yield based on the T-Bill Rate (2.74 USDC)
     */
    function test_MultipleRateYieldStrategyScenario_S2() public view {
        assertEq(
            2_739_726, // $1,000 * ((5% / 365) * 20) =  2.739726
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 20),
            "reduced rate yield wrong at deposit + 20 days"
        );
    }

    /**
     * S3
     * Scenario: User deposits 1000 USDC and redeems the APY after maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5% for the first 29 days
     *  And the APY jumps to 10% on day 30
     *  When the user requests to redeem the APY after 30 days
     *  Then the user should receive the yield based on 10% APY (8.22 USDC)
     *  And the principal should remain in the vault
     *
     * S4
     * Scenario: User deposits 1000 USDC and redeems the Principal after maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5% for the first 29 days
     *  And the APY jumps to 10% on day 30
     *  When the user requests to redeem the Principal after 30 days
     *  Then the user should receive their principal of 1000 USDC
     *  And the yield based on 10% APY (8.22 USDC)
     */
    function test_MultipleRateYieldStrategyScenario_S3_S4() public view {
        assertEq(
            8_219_178, // $1,000 * ((10% / 365) * 30) = 8.219178
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + MATURITY_PERIOD),
            "fully rate yield wrong at deposit + maturity days"
        );
    }

    /**
     * S5
     * Scenario: User tries to redeem the APY the same day they request redemption
     *  Given a user has deposited USDC into LiquidStone Plume
     *  And the user has accrued some yield
     *  When the user requests to redeem the APY
     *  And attempts to complete the redemption on the same day
     *  Then the system should not allow the redemption
     *  And should inform the user that a one-day notice is required for APY redemption
     */
    // NOTE (JL,2024-09-21): Not applicable for Yield Calculation.
    // function test_MultipleRateYieldStrategyScenario_S5() public { }

    /**
     * S6
     * Scenario: User tries to redeem the Principal the same day they request redemption
     *  Given a user has deposited USDC into LiquidStone Plume
     *  And the user has accrued some yield
     *  When the user requests to redeem the Principal
     *  And attempts to complete the redemption on the same day
     *  Then the system should not allow the redemption
     *  And should inform the user that a one-day notice is required for Principal redemption
     */
    // NOTE (JL,2024-09-21): Not applicable for Yield Calculation.
    // function test_MultipleRateYieldStrategyScenario_S6() public { }

    /**
     * S7
     * Scenario: User deposits 1000 USD, retains for extra cycle, redeems the APY before new cycle ends
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the user has completed one full 30-day cycle
     *  And the T-Bill Rate for the first cycle was 5%
     *  And the T-Bill Rate for the second cycle is 5.5%
     *  When the user requests to redeem the APY after 45 days (15 days into the second cycle)
     *  Then the user should receive the yield from the first cycle (8.22 USDC)
     *  And the prorated yield from the second cycle (2.26 USDC)
     *  And the principal should remain in the vault
     *
     *  NOTE (JL,2024-09-21): The 45 days above should be 46 days. Raised to Product.
     */
    function test_MultipleRateYieldStrategyScenario_S7() public {
        context.setReducedRate(31, PERCENT_5_5_SCALED);
        assertApproxEqAbs(
            10_479_452, // Full[30]+Reduced[15] = 8.2191781 + ($1,000 * ((5.5% / 365) * 15) = 10.479452
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 45),
            TOLERANCE,
            "full + reduced rate yield wrong at deposit + 45 days"
        );
    }

    /**
     * S8
     * Scenario: User deposits 1000 USD, retains for extra cycle, redeems the Principal before new cycle ends
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the user has completed one full 30-day cycle
     *  And the T-Bill Rate for the first cycle was 5%
     *  And the T-Bill Rate for the second cycle is 5.5%
     *  When the user requests to redeem the Principal after 50 days (20 days into the second cycle)
     *  Then the user should receive their principal of 1000 USDC
     *  And the yield from the first cycle (8.22 USDC)
     *  And the prorated yield from the second cycle (3.01 USDC)
     *
     *  NOTE (JL,2024-09-21): The 50 days above should be 51 days. Raised to Product.
     */
    function test_MultipleRateYieldStrategyScenario_S8() public {
        context.setReducedRate(31, PERCENT_5_5_SCALED);
        assertApproxEqAbs(
            11_232_876, // Full[30]+Reduced[20] = 8.2191781 + ($1,000 * ((5.5% / 365) * 20) = 11.232876
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + 50),
            TOLERANCE,
            "full + reduced rate yield wrong at deposit + 50 days"
        );
    }

    /**
     * S9
     * Scenario: User deposits 1000 USD, retains for extra cycle, redeems the APY after new cycle ends
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the user has completed two full 30-day cycles
     *  And the T-Bill Rate for the first cycle was 5%
     *  And the T-Bill Rate for the second cycle was 5.5%
     *  When the user requests to redeem the APY after 60 days
     *  Then the user should receive the yield from the first cycle (8.22 USDC)
     *  And the yield from the second cycle (8.22 USDC)
     *  And the principal should remain in the vault
     *
     * S10
     * Scenario: User deposits 1000 USD, retains for extra cycle, redeems the Principal after new cycle ends
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the user has completed two full 30-day cycles
     *  And the T-Bill Rate for the first cycle was 5%
     *  And the T-Bill Rate for the second cycle was 5.5%
     *  When the user requests to redeem the Principal after 60 days
     *  Then the user should receive their principal of 1000 USDC
     *  And the yield from the first cycle (8.22 USDC)
     *  And the yield from the second cycle (8.22 USDC)
     */
    function test_MultipleRateYieldStrategyScenario_S9_S10() public {
        context.setReducedRate(31, PERCENT_5_5_SCALED);
        assertApproxEqAbs(
            16_438_356, // $1,000 * ((10% / 365) * 60) = 16.438356
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + (2 * MATURITY_PERIOD)),
            TOLERANCE,
            "full rate yield wrong at deposit + 2x maturity"
        );
    }

    /**
     * MU-1
     * Scenario: Two users deposit at different funding rounds, both redeem at day 31 (day 1 and day 15)
     *  Given User A deposits 1000 USDC on day 1
     *  And User B deposits 1000 USDC on day 15
     *  And the T-Bill Rate is 5%
     *  When both users redeem their investments on day 31
     *  Then User A should receive 10% APY on their investment
     *  And User B should receive 5% APY on their investment
     */
    function test_MultipleRateYieldStrategyScenario_MU1() public view {
        // User A
        assertApproxEqAbs(
            8_219_178, // $1,000 * ((10% / 365) * 30) = 8.219718
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, depositPeriod + MATURITY_PERIOD),
            TOLERANCE,
            "full rate yield wrong at deposit + maturity"
        );

        // User B
        // Deposit on Day 15, Redeem Day 31 = 16 days at reduced rate.
        uint256 depositPeriodUserB = 15;
        assertApproxEqAbs(
            2_191_780, // $1,000 * ((5% / 365) * 16) = 2.191780
            yieldStrategy.calcYield(contextAddress, principal, depositPeriodUserB, depositPeriod + MATURITY_PERIOD),
            TOLERANCE,
            "reduced rate yield wrong at deposit + 15 days"
        );
    }

    /**
     * MU-2
     * Scenario: Two users deposit at different funding rounds, both redeem 15 days after day 31 (day 1 and day 15)
     *  Given User A deposits 1000 USDC on day 1
     *  And User B deposits 1000 USDC on day 15
     *  And the T-Bill Rate is 5% for the first cycle
     *  And the T-Bill Rate is 5.5% for the next cycle
     *  When both users redeem their investments 15 days after day 31
     *  Then User A should receive 10% APY for the first 30 days and 5.5% for the next 15 days
     *  And User B should receive 10% APY for the full 30 days
     */
    function test_MultipleRateYieldStrategyScenario_MU2() public {
        // Reduced Rate for second cycle.
        context.setReducedRate(31, PERCENT_5_5_SCALED);

        uint256 redemptionPeriod = 46;

        // User A
        assertApproxEqAbs(
            10_479_452, // Full[30]+Reduced[15] = 8.219178 + ($1,000 * ((5.5% / 365) * 15) = 10.479452
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redemptionPeriod),
            TOLERANCE,
            "full + reduced rate yield wrong at deposit + maturity + 15"
        );

        // User B
        // Deposit on Day 15, Redeem Day 46 = 1 full rate and 1 day at reduced rate.
        // Deposit on Day 16, Redeem Day 46 = 1 fullrate
        uint256 depositPeriodUserB = 16;
        assertApproxEqAbs(
            8_219_178, // $1,000 * ((10% / 365) * 30) = 8.219178
            yieldStrategy.calcYield(contextAddress, principal, depositPeriodUserB, redemptionPeriod),
            TOLERANCE,
            "full rate yield wrong at deposit + maturity"
        );
    }

    /**
     * MU-3
     * Scenario: Two users deposit at different funding round, with different T-Bill Rates, both redeem 14 days after
     *      day 31 (day 1 and day 15)
     *  Given User A deposits 1000 USDC on day 1
     *  And User B deposits 1000 USDC on day 15
     *  And the T-Bill Rate is 5% from day 1 to day 20
     *  And the T-Bill Rate is 5.5% from day 20 to day 45
     *  When both users redeem on day 45
     *  Then User A should receive 1010.33 USDC
     *  And User B should receive 1004.30 USDC
     *
     * SHOULD BE:
     *
     * Scenario: Two users deposit at different funding round, with different T-Bill Rates, both redeem 14 days after
     *      day 31 (day 1 and day 15)
     *  Given User A deposits 1000 USDC on day 1
     *  And User B deposits 1000 USDC on day 16
     *  And the T-Bill Rate is 5% from day 1 to day 19
     *  And the T-Bill Rate is 5.5% from day 20 to day 45
     *  When both users redeem on day 45
     *  Then User A should receive 1010.33 USDC
     *  And User B should receive 1004.32 USDC
     *
     * Calculation:
     * User A:
     * First 30 days yield (10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     * Remaining 14 days yield (5.5% APY) = 1000 * (5.5% / 365) * 14 = 2.11 USDC
     * Total yield = 8.22 + 2.11 = 10.33 USDC
     * Total redemption = 1000 + 10.33 = 1010.33 USDC
     *
     * User B:
     * First 4 days yield (5% APY) = 1000 * (5% / 365) * 4 = 0.0.55 USDC
     * Next 25 days yield (5.5% APY) = 1000 * (5.5% / 365) * 25 = 3.77 USDC
     * Total yield = 0.55 + 3.77 = 4.32 USDC
     * Total redemption = 1000 + 4.32 = 1004.32 USDC
     *
     */
    function test_MultipleRateYieldStrategyScenario_MU3() public {
        // Reduced Rate from Day 20 onwards.
        context.setReducedRate(20, PERCENT_5_5_SCALED);

        uint256 redemptionPeriod = 45;

        // User A
        assertApproxEqAbs(
            10_328_767, // Full[30]+Reduced[14] = 8.219178 + ($1,000 * ((5.5% / 365) * 14) = 10.328767
            yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redemptionPeriod),
            TOLERANCE,
            "full + reduced rate yield wrong at deposit + maturity + 15"
        );

        // User B
        // Deposit on Day 15, Redeem Day 45 = 30 days at full rate.
        // Deposit on Day 16, Redeem Day 45 = 29 days at reduced rate. The desired scenario!
        uint256 depositPeriodUserB = 16;
        assertApproxEqAbs(
            4_315_068, // ($1,000 * ((5% / 365) * 4)) + ($1,000 * ((5.5% / 365) * 25)) = 4.315068
            yieldStrategy.calcYield(contextAddress, principal, depositPeriodUserB, redemptionPeriod),
            TOLERANCE,
            "reduced rate yield wrong at deposit + 29"
        );
    }
}
