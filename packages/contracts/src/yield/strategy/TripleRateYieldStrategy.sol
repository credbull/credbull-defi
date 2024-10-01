// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

/**
 * @title TripleRateYieldStrategy
 * @dev Calculates returns using 1 'full' rate and 2 reduced rates, applied according to the Tenor Period, and
 *  depending on the holding period.
 */
contract TripleRateYieldStrategy is IYieldStrategy {
    /**
     * @inheritdoc IYieldStrategy
     */
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

        ITripleRateContext context = ITripleRateContext(contextContract);

        // Calculate interest for full-rate periods
        uint256 noOfFullRatePeriods = _noOfFullRatePeriods(context.numPeriodsForFullRate(), fromPeriod, toPeriod);
        yield = CalcSimpleInterest.calcInterest(
            principal, context.rateScaled(), noOfFullRatePeriods, context.frequency(), context.scale()
        );

        // Calculate interest for reduced-rate periods
        if (_noOfPeriods(fromPeriod, toPeriod) - noOfFullRatePeriods > 0) {
            uint256 firstReducedRatePeriod = _firstReducedRatePeriod(noOfFullRatePeriods, fromPeriod);
            ITripleRateContext.TenorPeriodRate memory currentTenorPeriodRate = context.currentTenorPeriodRate();

            // Previous Tenor Period ... Current Tenor Period ... 1st Reduced Rate Period ... To Period
            // If the 1st RR Period is on or after the current Tenor Period, then RR Interest is:
            //  1st RR Period -> To Period @ Current Rate.
            if (firstReducedRatePeriod >= currentTenorPeriodRate.effectiveFromTenorPeriod) {
                //  1st RR Period -> To Period @ Current Rate.
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    currentTenorPeriodRate.interestRate,
                    toPeriod - firstReducedRatePeriod,
                    context.frequency(),
                    context.scale()
                );
            }
            // Previous Tenor Period ... 1st Reduced Rate Period ... Current Tenor Period ... To Period
            // If the 1st RR Period is on or after the previous Tenor Period, then RR Interest is:
            //  1st RR Period -> Current Period @ Previous Rate +
            //  Current Period -> To Period @ Current Rate.
            else {
                ITripleRateContext.TenorPeriodRate memory previousTenorPeriodRate = context.previousTenorPeriodRate();

                //  1st RR Period -> Current Period @ Previous Rate +
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    previousTenorPeriodRate.interestRate,
                    currentTenorPeriodRate.effectiveFromTenorPeriod - firstReducedRatePeriod,
                    context.frequency(),
                    context.scale()
                );

                //  Current Period -> To Period @ Current Rate.
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    currentTenorPeriodRate.interestRate,
                    toPeriod - currentTenorPeriodRate.effectiveFromTenorPeriod,
                    context.frequency(),
                    context.scale()
                );
            }
        }
    }

    /**
     * @inheritdoc IYieldStrategy
     */
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        virtual
        returns (uint256 price)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        ITripleRateContext context = ITripleRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.rateScaled(), context.frequency(), context.scale()
        );
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
