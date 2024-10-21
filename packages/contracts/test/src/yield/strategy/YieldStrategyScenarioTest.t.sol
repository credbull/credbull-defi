// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

abstract contract YieldStrategyScenarioTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant DEFAULT_FULL_RATE = PERCENT_10_SCALED;
    uint256 public constant DEFAULT_REDUCED_RATE = PERCENT_5_SCALED;

    uint256 public constant EFFECTIVE_FROM_PERIOD = 0;
    uint256 public constant MATURITY_PERIOD = 30;

    uint256 public immutable DEFAULT_FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    uint256 internal principal;
    uint256 internal depositPeriod;

    function _yieldStrategy() internal virtual returns (IYieldStrategy);

    function _contextAddress() internal virtual returns (address);

    function _setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_) internal virtual;

    function setUp() public virtual {
        principal = 1_000 * SCALE;
        depositPeriod = 1;
    }

    /**
     * # S1
     * Scenario: User deposits 1000 USDC and redeems the APY before maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5%
     *  When the user requests to redeem the APY after 15 days
     *  Then the user should receive the prorated yield (2.055 USDC)
     *  And the principal should remain in the vault
     *
     * Calculation:
     *  Daily yield rate = 5% / 365 = 0.0137%
     *  Yield for 15 days = 1000 * 0.0137% * 15 = 2.055 USDC
     */
    function test_YieldStrategyScenarioTest_S1() public {
        // $1,000 * ((5% / 365) * 15) =  2.054794
        assertEq(
            2_054_794,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, 16),
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
     *
     * Calculation:
     *  Daily yield rate = 5% / 365 = 0.0137%
     *  Yield for 20 days = 1000 * 0.0137% * 20 = 2.74 USDC
     *  Total redemption = 1000 + 2.74 = 1002.74 USDC
     */
    function test_YieldStrategyScenarioTest_S2() public {
        // $1,000 * ((5% / 365) * 20) =  2.739726
        assertEq(
            2_739_726,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, 21),
            "reduced rate yield wrong at deposit + 20 days"
        );
    }

    /**
     * S3
     * Scenario: User deposits 1000 USDC and redeems the APY after maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5% for the first 29 days
     *  And the APY jumps to 10% on day 31
     *  When the user requests to redeem the APY after 30 days
     *  Then the user should receive the yield based on 10% APY (8.22 USDC)
     *  And the principal should remain in the vault
     *
     * Calculation:
     *  Yield for 30 days at 10% APY = 1000 * (10% / 365) * 30 = 8.22 USDC
     *
     * S4
     * Scenario: User deposits 1000 USDC and redeems the Principal after maturity
     *  Given a user has deposited 1000 USDC into LiquidStone Plume
     *  And the T-Bill Rate is 5% for the first 29 days
     *  And the APY jumps to 10% on day 31
     *  When the user requests to redeem the Principal after 30 days
     *  Then the user should receive their principal of 1000 USDC
     *  And the yield based on 10% APY (8.22 USDC)
     *
     * Calculation:
     *  Yield for 30 days at 10% APY = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Total redemption = 1000 + 8.22 = 1008.22 USDC
     */
    function test_YieldStrategyScenarioTest_S3_S4() public {
        // $1,000 * ((10% / 365) * 30) = 8.219178
        assertEq(
            8_219_178,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, MATURITY_PERIOD + 1),
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
    // function test_YieldStrategyScenarioTest_S5() public { }

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
    // function test_YieldStrategyScenarioTest_S6() public { }

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
     * Calculation:
     *  First cycle yield (30 days at 10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Second cycle partial yield (15 days at 5.5%) = 1000 * (5.5% / 365) * 15 = 2.26 USDC
     *  Total yield = 8.22 + 2.26 = 10.48 USDC
     */
    function test_YieldStrategyScenarioTest_S7() public {
        _setReducedRate(PERCENT_5_5_SCALED, 31);

        // $1,000 * ((10% / 365) * 30) + $1,000 * ((5.5% / 365) * 15) = 10.479452
        assertApproxEqAbs(
            10_479_452,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, 46),
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
     * Calculation:
     *  First cycle yield (30 days at 10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Second cycle partial yield (20 days at 5.5%) = 1000 * (5.5% / 365) * 20 = 3.01 USDC
     *  Total redemption = 1000 + 8.22 + 3.01 = 1011.23 USDC
     */
    function test_YieldStrategyScenarioTest_S8() public {
        _setReducedRate(PERCENT_5_5_SCALED, 31);

        // $1,000 * ((10% / 365) * 30) + $1,000 * ((5.5% / 365) * 20) = 11.232876
        assertApproxEqAbs(
            11_232_876,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, 51),
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
     * Calculation:
     *  First cycle yield (30 days at 10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Second cycle yield (30 days at 10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Total yield = 8.22 + 8.22 = 16.44 USDC
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
     *
     * Calculation:
     *  First cycle yield (30 days at 10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Second cycle yield (30 days at 10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *  Total redemption = 1000 + 8.22 + 8.22 = 1016.44 USDC
     */
    function test_YieldStrategyScenarioTest_S9_S10() public {
        _setReducedRate(PERCENT_5_5_SCALED, 31);

        // $1,000 * ((10% / 365) * 60) = 16.438356
        assertApproxEqAbs(
            16_438_356,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, (2 * MATURITY_PERIOD) + 1),
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
     *
     * Calculation:
     *  User A redemption = 1000 + (1000 * 10% * 30/365) = 1008.22 USDC
     *  User B redemption = 1000 + (1000 * 5% * 15/365) = 1002.05 USDC
     *
     * NOTE (JL,2024-10-03): As deposit day is inclusive for yield calculation, for User A redeeming on Day 30 is
     *  1 Tenor/Maturity Period and yields 10% APY.
     *  For User B, depositing on Day 15 and redeeming on Day 30 is actually 16 days.
     *  Communicated to product.
     */
    function test_YieldStrategyScenarioTest_MU1() public {
        // User A
        // Deposit on Day 1, Redeem Day 30 = 30 days at full rate.
        // $1,000 * ((10% / 365) * 30) = 8.219718
        assertApproxEqAbs(
            8_219_178,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, MATURITY_PERIOD + 1),
            TOLERANCE,
            "full rate yield wrong at deposit + maturity"
        );

        // User B
        // Deposit on Day 15, Redeem Day 30 = 16 days at reduced rate.
        // $1,000 * ((5% / 365) * 16) = 2.191780
        assertApproxEqAbs(
            2_191_780,
            _yieldStrategy().calcYield(_contextAddress(), principal, 15, MATURITY_PERIOD + 1),
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
     *
     * Calculation:
     *  User A redemption = 1000 + (1000 * 10% * 30/365) + (1000 * 5.5% * 15/365) = 1010.48 USDC
     *  User B redemption = 1000 + (1000 * 10% * 30/365) = 1008.22 USDC
     *
     * NOTE (JL,2024-10-03): As deposit day is inclusive for yield calculation, for User A redeeming on Day 46 is
     *  1 Maturity Period @ 10% APY and 16 days @ 5.5% APY.
     *  For User B, depositing on Day 15 and redeeming on Day 46 is 1 Maturity Period @ 10% APY and 2 days @ 5.5% APY.
     *  Communicated to product.
     */
    function test_YieldStrategyScenarioTest_MU2() public {
        // Reduced Rate for second cycle.
        _setReducedRate(PERCENT_5_5_SCALED, 31);

        // User A
        // Deposit on Day 1, Redeem Day 46 = 30 days at full rate and 15 days at reduced rate.
        // $1,000 * ((10% / 365) * 30) + 1,000 * ((5.5% / 365) * 15) = 10.479452
        assertApproxEqAbs(
            10_479_452,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, 46),
            TOLERANCE,
            "full + reduced rate yield wrong at deposit + maturity + 15"
        );

        // User B
        // Deposit on Day 15, Redeem Day 46 = 1 full rate and 2 days at reduced rate.
        // $1,000 * ((10% / 365) * 30) + 1,000 * ((5.5% / 365) * 1) = 8.369863
        assertApproxEqAbs(
            8_369_863,
            _yieldStrategy().calcYield(_contextAddress(), principal, 15, 46),
            TOLERANCE,
            "full rate yield wrong at deposit + maturity"
        );
    }

    /**
     * MU-3
     * Scenario: Two users deposit at different funding round, with different T-Bill Rates, both redeem 14 days after
     *         day 31 (day 1 and day 15)
     *  Given User A deposits 1000 USDC on day 1
     *  And User B deposits 1000 USDC on day 15
     *  And the T-Bill Rate is 5% from day 1 to day 20
     *  And the T-Bill Rate is 5.5% from day 20 to day 45
     *  When both users redeem on day 45
     *  Then User A should receive 1010.33 USDC
     *  And User B should receive 1004.30 USDC
     *
     * Calculation:
     *  User A:
     *   First 30 days yield (10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC
     *   Remaining 14 days yield (5.5% APY) = 1000 * (5.5% / 365) * 14 = 2.11 USDC
     *   Total yield = 8.22 + 2.11 = 10.33 USDC
     *   Total redemption = 1000 + 10.33 = 1010.33 USDC
     *
     *  User B:
     *   First 5 days yield (5% APY) = 1000 * (5% / 365) * 5 = 0.68 USDC
     *   Next 24 days yield (5.5% APY) = 1000 * (5.5% / 365) * 24 = 3.62 USDC
     *   Total yield = 0.68 + 3.62 = 4.30 USDC
     *   Total redemption = 1000 + 4.30 = 1004.30 USDC
     *
     * NOTE (JL,2024-10-03): Exact numbers and calculations modified to capture the spirit of the Scenario.
     */
    function test_YieldStrategyScenarioTest_MU3() public {
        // Reduced Rate from Day 20 onwards.
        _setReducedRate(PERCENT_5_5_SCALED, 20);

        // User A
        // Deposit on Day 1, Redeem Day 45 = 30 days at full rate and 14 days at 5.5% APY.
        // $1,000 * ((10% / 365) * 30) + 1,000 * ((5.5% / 365) * 14) = 10.328767
        assertApproxEqAbs(
            10_328_767,
            _yieldStrategy().calcYield(_contextAddress(), principal, 1, 45),
            TOLERANCE,
            "full + reduced rate yield wrong at deposit + maturity + 14"
        );

        // User B
        // Deposit on Day 16, Redeem Day 45 = 29 days at reduced rates.
        // $1,000 * ((5% / 365) * 3) + $1,000 * ((5.5% / 365) * 26) = 4.328767
        assertApproxEqAbs(
            4_328_767,
            _yieldStrategy().calcYield(_contextAddress(), principal, 16, 45),
            TOLERANCE,
            "reduced rate yield wrong at deposit + 29"
        );
    }
}
