// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

import { IMultipleRateContext } from "@test/test/yield/context/IMultipleRateContext.t.sol";

/**
 * @title MultipleRateYieldStrategy
 * @dev Calculates returns using different rates depending on the holding period.
 */
contract MultipleRateYieldStrategy is IYieldStrategy {
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        returns (uint256 yield)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        if (fromPeriod >= toPeriod) {
            revert IYieldStrategy_InvalidPeriodRange(fromPeriod, toPeriod);
        }

        IMultipleRateContext context = IMultipleRateContext(contextContract);

        // Calculate interest for full-rate periods
        uint256 noOfFullRatePeriods = _noOfFullRatePeriods(context.numPeriodsForFullRate(), fromPeriod, toPeriod);
        yield = CalcSimpleInterest.calcInterest(
            principal, context.rateScaled(), noOfFullRatePeriods, context.frequency(), context.scale()
        );

        // Calculate interest for reduced-rate periods
        if (_noOfPeriods(fromPeriod, toPeriod) - noOfFullRatePeriods > 0) {
            yield += _calcReducedRateInterest(
                principal,
                context.frequency(),
                context.scale(),
                toPeriod,
                _firstReducedRatePeriod(noOfFullRatePeriods, fromPeriod),
                context.reducedRatesFor(_firstReducedRatePeriod(noOfFullRatePeriods, fromPeriod), toPeriod)
            );
        }
    }

    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        virtual
        returns (uint256 price)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }

        // NOTE (JL,2024-09-25): Seeing as this only uses Full Rate, I left it alone.
        IMultipleRateContext context = IMultipleRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.rateScaled(), context.frequency(), context.scale()
        );
    }

    /**
     * @dev Calculates the total Reduced Rate Interest.
     *
     * @param principal The Principal Amount.
     * @param frequency The Frequency of the interest calculation.
     * @param scale The Scale of the incoming numbers.
     * @param toPeriod The `toPeriod` that we are calculating up until.
     * @param firstReducedRatePeriod The first Reduced Rate Period.
     * @param reducedRateScaled The array of Reduced Rates that apply to the Period Range.
     * @return The calculated Reduced Rate Interest.
     */
    function _calcReducedRateInterest(
        uint256 principal,
        uint256 frequency,
        uint256 scale,
        uint256 toPeriod,
        uint256 firstReducedRatePeriod,
        uint256[][] memory reducedRateScaled
    ) internal pure returns (uint256) {
        uint256 reducedRateInterest;
        uint256 _periods;
        uint256 _rate;

        // A singluar Reduced Rate applies to the Period Range.
        if (reducedRateScaled.length == 1) {
            _periods = toPeriod - firstReducedRatePeriod;
            _rate = reducedRateScaled[0][1];
            reducedRateInterest += CalcSimpleInterest.calcInterest(principal, _rate, _periods, frequency, scale);
        }
        // Two Reduced Rates apply to the Period Range.
        else if (reducedRateScaled.length == 2) {
            // Apply each rate in series.
            _periods = reducedRateScaled[1][0] - firstReducedRatePeriod;
            _rate = reducedRateScaled[0][1];
            reducedRateInterest += CalcSimpleInterest.calcInterest(principal, _rate, _periods, frequency, scale);

            _periods = toPeriod - reducedRateScaled[1][0];
            _rate = reducedRateScaled[1][1];
            reducedRateInterest += CalcSimpleInterest.calcInterest(principal, _rate, _periods, frequency, scale);
        }
        // Three or more Reduced Rates apply across the Period Range.
        else {
            // Iterate over the rates applying them using lookbehind.
            for (uint256 i = 1; i < reducedRateScaled.length; i++) {
                // The second rate (first rate is not explicitly processed)
                if (i == 1) {
                    // Period based on the 1st RR Period and this rates Period.
                    _periods = reducedRateScaled[i][0] - firstReducedRatePeriod;
                    // Rate is the 1st Rate
                    _rate = reducedRateScaled[i - 1][1];
                }
                // The last rate
                else if (i == reducedRateScaled.length - 1) {
                    // Period is from this rates effectve period to the terminal `to` period.
                    _periods = toPeriod - reducedRateScaled[i][0];
                    // Rate is this rate.
                    _rate = reducedRateScaled[i][1];
                }
                // Every other rate (2 -> length-1)
                else {
                    // Period based on the period gap between rates.
                    _periods = reducedRateScaled[i][0] - reducedRateScaled[i - 1][0];
                    // Rate is the preceeding rate.
                    _rate = reducedRateScaled[i - 1][1];
                }
                reducedRateInterest += CalcSimpleInterest.calcInterest(principal, _rate, _periods, frequency, scale);
            }
        }
        return reducedRateInterest;
    }

    /**
     * @dev Utility function to calculate the Number Of Periods between `from_` and `to_`. Also reduces Stack Depth in
     *  invoking functions.
     *
     * @param from_ The from period
     * @param to_ The to period
     */
    function _noOfPeriods(uint256 from_, uint256 to_) internal pure returns (uint256) {
        return to_ - from_;
    }

    /**
     * @dev Calculates the number of Full Rate Periods.
     *
     * @param _noOfPeriodsForFullRate  The number of periods that apply for Full Rate.
     * @param _from The from period
     * @param _to The to period
     * @return The calculated number of Full Rate Periods.
     */
    function _noOfFullRatePeriods(uint256 _noOfPeriodsForFullRate, uint256 _from, uint256 _to)
        internal
        pure
        returns (uint256)
    {
        uint256 _periods = _noOfPeriods(_from, _to);
        return _periods - (_periods % _noOfPeriodsForFullRate);
    }

    /**
     * @dev Calculates the first Reduced Rate Period.
     *
     * @param noOfFullRatePeriods_  The number of Full Rate Periods
     * @param _from  The from period.
     * @return The calculated first Reduced Rate Period.
     */
    function _firstReducedRatePeriod(uint256 noOfFullRatePeriods_, uint256 _from) internal pure returns (uint256) {
        return noOfFullRatePeriods_ != 0 ? _from + noOfFullRatePeriods_ : _from;
    }
}