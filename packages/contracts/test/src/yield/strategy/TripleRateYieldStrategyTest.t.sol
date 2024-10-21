// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";
import { TestTripleRateContext } from "@test/test/yield/context/TestTripleRateContext.t.sol";

import { Test } from "forge-std/Test.sol";

contract TripleRateYieldStrategyTest is Test {
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

    uint256 public immutable DEFAULT_FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

    IYieldStrategy internal yieldStrategy;
    TestTripleRateContext internal context;
    address internal contextAddress;
    uint256 internal principal;

    function setUp() public {
        yieldStrategy = new TripleRateYieldStrategy(IYieldStrategy.RangeInclusion.To);

        context = contextFactory(
            TripleRateContext.ContextParams({
                fullRateScaled: DEFAULT_FULL_RATE,
                initialReducedRate: ITripleRateContext.PeriodRate({
                    interestRate: DEFAULT_REDUCED_RATE,
                    effectiveFromPeriod: EFFECTIVE_FROM_PERIOD
                }),
                frequency: DEFAULT_FREQUENCY,
                tenor: MATURITY_PERIOD,
                decimals: DECIMALS
            })
        );
        contextAddress = address(context);
        principal = 1_000 * SCALE;
    }

    function test_TripleRateYieldStrategy_RevertCalcYield_WhenInvalidContextAddress() public {
        vm.expectRevert(IYieldStrategy.IYieldStrategy_InvalidContextAddress.selector);
        yieldStrategy.calcYield(address(0), principal, 1, MATURITY_PERIOD);
    }

    function test_TripleRateYieldStrategy_RevertCalcPrice_WhenInvalidContextAddress() public {
        vm.expectRevert(IYieldStrategy.IYieldStrategy_InvalidContextAddress.selector);
        yieldStrategy.calcPrice(address(0), 5);
    }

    function test_TripleRateYieldStrategy_RevertCalcYield_WhenInvalidPeriodRange() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, 5, 3, yieldStrategy.rangeInclusion()
            )
        );
        yieldStrategy.calcYield(contextAddress, principal, 5, 3);
    }

    function test_TripleRateYieldStrategy_CalcYield_Static() public {
        TripleRateContext.ContextParams memory params;
        params.frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_365);
        context = contextFactory(params);
        contextAddress = address(context);

        // 21 Days:
        // $1,000 * ((5% / 365) * 21) = 2.876712
        assertApproxEqAbs(
            2_876_712,
            yieldStrategy.calcYield(contextAddress, principal, 1, 22),
            TOLERANCE,
            "incorrect 21 day reduced rate yield"
        );

        // 29 Days:
        // $1,000 * ((5% / 365) * 29) = 3.972603
        assertApproxEqAbs(
            3_972_603,
            yieldStrategy.calcYield(contextAddress, principal, 1, 30),
            TOLERANCE,
            "incorrect 29 day reduced rate yield"
        );

        // 30 Days:
        // $1,000 * ((10% / 365) * 30) = 8.219178
        assertApproxEqAbs(
            8_219_178,
            yieldStrategy.calcYield(contextAddress, principal, 1, 31),
            TOLERANCE,
            "incorrect 30 day full rate yield"
        );

        // 32 Days, no current Period Rate update:
        // $1,000 * ((10% / 365) * 30) + $1,000 * ((5% / 365) * 2) = 8.493151
        assertApproxEqAbs(
            8_493_151,
            yieldStrategy.calcYield(contextAddress, principal, 1, 33),
            TOLERANCE,
            "incorrect 32 day combined rate yield"
        );

        // Update current Period Rate at Day 31:
        context.setReducedRate(PERCENT_5_5_SCALED, 31);

        // 37 Days:
        // $1,000 * ((10% / 365) * 30) + $1,000 * ((5.5% / 365) * 7) = 9.273973
        assertApproxEqAbs(
            9_273_973,
            yieldStrategy.calcYield(contextAddress, principal, 1, 38),
            TOLERANCE,
            "incorrect 37 day combined rate yield"
        );

        // 22 Days, period range spans Previous and Current Period Rate:
        // $1,000 * ((5% / 365) * 10) + $1,000 * ((5.5% / 365) * 12) = 3.178082
        assertApproxEqAbs(
            3_178_082,
            yieldStrategy.calcYield(contextAddress, principal, 20, 42),
            TOLERANCE,
            "incorrect 22 day across current period rate yield"
        );

        // 10 Days, entire range before the Current Period Rate:
        // $1,000 * ((5% / 365) * 10) = 1.369863
        assertApproxEqAbs(
            1_369_863,
            yieldStrategy.calcYield(contextAddress, principal, 20, 30),
            TOLERANCE,
            "incorrect 10 day yield before current period rate"
        );

        // 6 Days, entire range after the Current Period Rate:
        // $1,000 * ((5.5% / 365) * 6) = 0.904110
        assertApproxEqAbs(
            904_110,
            yieldStrategy.calcYield(contextAddress, principal, 32, 38),
            TOLERANCE,
            "incorrect 10 day yield before current period rate"
        );
    }

    /**
     * @notice Fuzz tests Yield Calculation where the Yield is always mature.
     * @dev This avoids having to deal with the Current and Previous Period Rates. To ease the fuzzing, we get a 'to'
     *  and calculate a 'from' (`noOfCycles` in the past) that ensures only mature yield.
     *
     * @param rawPrincipal The unscaled Principal, must be > 1.
     * @param to The To Period, must be less than 1m and allow for the 'from' calculation.
     * @param noOfCycles The Number of Maturity Cycles to use to calculate the 'from'. Must be > 0.
     */
    function test_TripleRateYieldStrategy_CalcYield_AlwaysMature(uint128 rawPrincipal, uint24 to, uint8 noOfCycles)
        public
        view
    {
        vm.assume(rawPrincipal > 1);
        vm.assume(noOfCycles > 0);
        vm.assume(to >= noOfCycles * context.numPeriodsForFullRate() && to < 1_000_000);

        uint256 from = to - (noOfCycles * context.numPeriodsForFullRate());
        uint256 scaledPrincipal = rawPrincipal * SCALE;
        // This is also the No Of Full Rate Periods.
        (uint256 noOfPeriods,,) = yieldStrategy.periodRangeFor(from, to);

        uint256 expectedYield = CalcSimpleInterest.calcInterest(
            scaledPrincipal, context.rateScaled(), noOfPeriods, context.frequency(), context.scale()
        );

        string memory label = string.concat("Principal= ", vm.toString(scaledPrincipal));
        label = string.concat(label, string.concat(", From= ", vm.toString(from)));
        label = string.concat(label, string.concat(", To= ", vm.toString(to)));
        assertApproxEqAbs(
            expectedYield,
            yieldStrategy.calcYield(contextAddress, scaledPrincipal, from, to),
            TOLERANCE,
            string.concat(label, ": Incorrect Mature Yield")
        );
    }

    function test_TripleRateYieldStrategy_CalcYield_AlwaysMature_VariableTenor(
        uint128 rawPrincipal,
        uint24 to,
        uint8 noOfCycles,
        uint8 tenor
    ) public {
        vm.assume(rawPrincipal > 1);
        vm.assume(noOfCycles > 0);
        vm.assume(tenor > 0);
        vm.assume(to >= uint24(noOfCycles) * tenor && to < 10_000_000);

        // Create a context with the variable Tenor/Maturity Period.
        TripleRateContext.ContextParams memory params;
        params.tenor = tenor;
        context = contextFactory(params);
        contextAddress = address(context);

        uint256 from = to - (noOfCycles * context.numPeriodsForFullRate());
        uint256 scaledPrincipal = rawPrincipal * SCALE;
        // This is also the No Of Full Rate Periods.
        (uint256 noOfPeriods,,) = yieldStrategy.periodRangeFor(from, to);

        uint256 expectedYield = CalcSimpleInterest.calcInterest(
            scaledPrincipal, context.rateScaled(), noOfPeriods, context.frequency(), context.scale()
        );

        string memory label = string.concat("Principal= ", vm.toString(scaledPrincipal));
        label = string.concat(label, string.concat(", Tenor= ", vm.toString(tenor)));
        label = string.concat(label, string.concat(", From= ", vm.toString(from)));
        label = string.concat(label, string.concat(", To= ", vm.toString(to)));
        assertApproxEqAbs(
            expectedYield,
            yieldStrategy.calcYield(contextAddress, scaledPrincipal, from, to),
            TOLERANCE,
            string.concat(label, ": Incorrect Mature Yield With Variable Tenor")
        );
    }

    /**
     * @dev Due to the 'Triple Rate' nature, we cannot manage unlimited 'from' and 'to' boundaries. This test mimics a
     *  real-world usage. Operations sets the 'reduced' Interest Rate at 'tenor' periods, consistently. This means that
     *  a valid 'to' is after the Effective From period of the last setting. In this test, we mimic a year, so we just
     *  allow the 'to' to be 365. This means we are guaranteed a 'full' and 'reduced' interest rate bases yield.
     */
    function test_TripleRateYieldStrategy_CalcYield_1Year_Dynamic(uint128 rawPrincipal, uint8 from) public {
        vm.assume(rawPrincipal > 1);
        // The 'to' must be less than a 'tenor period' more than the Current Period Rate. So, we just use 365.
        uint16 to = 365;
        vm.assume(from < to);

        // Set a 'reduced' Interest Rate per Tenor/Maturity Period. We use 3.x% incrementing.
        uint32 baseInterestRate = 30;
        uint32[][] memory periodToRate = new uint32[][]((365 / context.numPeriodsForFullRate()) + 1);
        for (uint24 i = 0; i <= 365 / context.numPeriodsForFullRate(); ++i) {
            uint16 period = uint16(context.numPeriodsForFullRate() * i) + 1; // Truncation
            uint32 interestRate = uint32((baseInterestRate + i) * SCALE) / 10; // Truncation

            context.setReducedRate(interestRate, period);

            periodToRate[i] = new uint32[](2);
            periodToRate[i][0] = period;
            periodToRate[i][1] = interestRate;
        }

        uint256 scaledPrincipal = rawPrincipal * SCALE;
        (uint256 noOfPeriods,,) = yieldStrategy.periodRangeFor(from, to);
        uint256 noOfFullRatePeriods = noOfPeriods - (noOfPeriods % context.numPeriodsForFullRate());

        // NOTE (JL,2024-10-16): The following code closely mimics the actual code, so is proof against regression. But
        //  comes with an added cost of updating this code when the main code changes.
        uint256 expectedYield;
        if (noOfFullRatePeriods > 0) {
            expectedYield += CalcSimpleInterest.calcInterest(
                scaledPrincipal, context.rateScaled(), noOfFullRatePeriods, context.frequency(), context.scale()
            );
        }
        if (noOfPeriods - noOfFullRatePeriods > 0) {
            uint256 firstReducedRatePeriod = noOfFullRatePeriods != 0 ? from + noOfFullRatePeriods : from;
            uint256 rateIndex = firstReducedRatePeriod / context.numPeriodsForFullRate();
            uint256 startPeriod = firstReducedRatePeriod;
            for (uint256 i = rateIndex; i < periodToRate.length; ++i) {
                uint32 endPeriod;
                if (i == periodToRate.length - 1) {
                    endPeriod = to;
                } else {
                    endPeriod = periodToRate[rateIndex + 1][0] - 1;
                }
                uint32 interestRate = periodToRate[i][1];
                expectedYield += CalcSimpleInterest.calcInterest(
                    scaledPrincipal, interestRate, endPeriod - startPeriod, context.frequency(), context.scale()
                );

                startPeriod = endPeriod;
            }
        }

        string memory label = string.concat("Principal= ", vm.toString(scaledPrincipal));
        label = string.concat(label, string.concat(", From= ", vm.toString(from)));
        label = string.concat(label, string.concat(", To= ", vm.toString(to)));
        assertApproxEqAbs(
            expectedYield,
            yieldStrategy.calcYield(contextAddress, scaledPrincipal, from, to),
            TOLERANCE,
            string.concat(label, ": Incorrect Dynamic Yield ")
        );
    }

    /**
     * If we attempt to Calculate a Yield where the first 'reduced' Interest Rate Period falls before the Previous
     * Period Rate Effective From Period, then we do not have a record of the Interest Rate to apply.
     *
     * How could this happen? Technically, highly unlikely I think, as time advances (the periods) doing a Yield
     * Calculation with a long-ago 'from' period and a 'to' period that does not include any maturity is the only way.
     * In practice, the 'to' period will almost always be 'today', meaning that avoiding maturity is highly unlikely.
     * Basically, historical calculations are disallowed.  Also, IF Operations fails to set a 'reduced' Interest Rate
     * for a long period, that may also be an issue.
     *
     * In any case, this test proves that the `TripleRateYieldStrategy` will revert any such attempts, causing no state
     * change.
     */
    function test_TripleRateYieldStrategy_CalcYield_RevertWhen_FRRPEarlierThanPerviousPeriodRate() public {
        // We set 2 Period Rates, so any 'from' earlier than the Previous Period Rate Effective Period (at Period 31)
        // will fail.
        context.setReducedRate(PERCENT_5_5_SCALED, 31); // Previous Period Rate
        context.setReducedRate(PERCENT_10_SCALED, 61); // Current Period Rate

        // Then we attempt a yield calculation for a period range where the 'from' falls before the Previous Period Rate
        // Effective Period. This is only possible if historical Yield Calculations are possible. If the
        vm.expectRevert(
            abi.encodeWithSelector(
                TripleRateYieldStrategy.TripleRateYieldStrategy_DepositPeriodOutsideInterestRatePeriodRange.selector,
                0,
                31,
                61
            )
        );
        // 0-26 means no 'full' Interest Rate and 0 is the first 'reduced' Interest Rate Period.
        yieldStrategy.calcYield(contextAddress, principal, 0, 26);
    }

    function test_TripleRateYieldStrategy_CalcPrice_WorksConsistently(uint32 periodsElapsed) public view {
        // Limit Periods Elapsed to a conservative maximum of 274,000 years(!).
        vm.assume(periodsElapsed < 100_000_000);

        uint256 expectedPrice = CalcSimpleInterest.calcPriceFromInterest(
            periodsElapsed, context.rateScaled(), context.frequency(), context.scale()
        );
        assertEq(
            expectedPrice,
            yieldStrategy.calcPrice(contextAddress, periodsElapsed),
            string.concat("Incorrect Price for Elapsed Periods= ", vm.toString(periodsElapsed))
        );
    }

    function orDefault(uint256 value, uint256 defaultValue) private pure returns (uint256 _value) {
        _value = value == 0 ? defaultValue : value;
    }

    function contextFactory(TripleRateContext.ContextParams memory params)
        private
        returns (TestTripleRateContext _context)
    {
        _context = new TestTripleRateContext();
        _context = TestTripleRateContext(
            address(
                new ERC1967Proxy(
                    address(_context),
                    abi.encodeWithSelector(
                        _context.__TestTripleRateContext_init.selector,
                        orDefault(params.fullRateScaled, DEFAULT_FULL_RATE),
                        orDefault(params.initialReducedRate.interestRate, DEFAULT_REDUCED_RATE),
                        orDefault(params.initialReducedRate.effectiveFromPeriod, EFFECTIVE_FROM_PERIOD),
                        orDefault(params.frequency, DEFAULT_FREQUENCY),
                        orDefault(params.tenor, MATURITY_PERIOD),
                        orDefault(params.decimals, DECIMALS)
                    )
                )
            )
        );
    }
}
