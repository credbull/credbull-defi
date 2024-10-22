// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { YieldStrategy } from "@credbull/yield/strategy/YieldStrategy.sol";

/**
 * @title TripleRateYieldStrategy
 * @dev Calculates returns using 1 'full' rate and 2 'reduced' rates, applied according to the Tenor Period, and
 *  depending on the holding period.
 */
contract TripleRateYieldStrategy is YieldStrategy {
    constructor(RangeInclusion rangeInclusion_) YieldStrategy(rangeInclusion_) { }

    /**
     * @notice Reverts when the `depositPeriod` falls outside the period range of 'reduced' Interest Rate data.
     * @dev This should never happen, as it indicates an operational failure, where the 'reduced' Interest Rate has not
     *  been set correctly (for multiple tenor periods!).
     *
     * @param depositPeriod The Deposit Period for which we sought a 'reduced' Interest Rate.
     * @param previousPeriod The earliest Period for which we retain a 'reduced' Interest Rate.
     * @param currentPeriod The current Period at which the current 'reduced' Interest Rate applies.
     */
    error TripleRateYieldStrategy_DepositPeriodOutsideInterestRatePeriodRange(
        uint256 depositPeriod, uint256 previousPeriod, uint256 currentPeriod
    );

    /**
     * @inheritdoc YieldStrategy
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        override
        returns (uint256 yield)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        (uint256 noOfPeriods,,) = periodRangeFor(fromPeriod, toPeriod);
        ITripleRateContext context = ITripleRateContext(contextContract);

        // Calculate interest for full-rate periods
        uint256 noOfFullRatePeriods = _noOfFullRatePeriods(context.numPeriodsForFullRate(), fromPeriod, toPeriod);
        if (noOfFullRatePeriods > 0) {
            yield = _calcInterest(context, principal, noOfFullRatePeriods);
        }

        // Calculate interest for reduced-rate periods
        if (noOfPeriods - noOfFullRatePeriods > 0) {
            uint256 firstReducedRatePeriod = _firstReducedRatePeriod(noOfFullRatePeriods, fromPeriod);
            ITripleRateContext.PeriodRate memory currentPeriodRate = context.currentPeriodRate();
            ITripleRateContext.PeriodRate memory previousPeriodRate = context.previousPeriodRate();

            // Timeline: Previous Period Rate -> Current Period Rate -> 1st Reduced Rate Period -> To Period
            // If the first 'reduced' interest rate period (FRRP) is on or after the current Period Rate, then the
            // 'reduced' Yield is:
            //  (FRRP -> To Period) @ Current Rate.
            if (firstReducedRatePeriod >= currentPeriodRate.effectiveFromPeriod) {
                //  1st RR Period -> To Period @ Current Rate.
                yield +=
                    _calcInterest(context, principal, toPeriod - firstReducedRatePeriod, currentPeriodRate.interestRate);
            }
            // Timeline: Previous Period Rate -> 1st Reduced Rate Period -> To Period -> Current Period Rate
            // If the FRRP is on or after the previous Period Rate and the 'to' period is before the current Period
            // Rate, then the 'reduced' Yield is:
            //  (FRRP -> To Period) @ Previous Rate
            else if (
                firstReducedRatePeriod >= previousPeriodRate.effectiveFromPeriod
                    && toPeriod < currentPeriodRate.effectiveFromPeriod
            ) {
                //  1st RR Period -> To Period @ Previous Rate.
                yield += _calcInterest(
                    context, principal, toPeriod - firstReducedRatePeriod, previousPeriodRate.interestRate
                );
            }
            // Timeline: Previous Period Rate -> 1st Reduced Rate Period -> Current Period Rate -> To Period
            // If the FRRP is on or after the previous Period Rate and the 'to' period is on or after the current Period
            // Rate, then the 'reduced' Yield is:
            //  (FRRP -> Current Period Rate - 1) @ Previous Rate +
            //  Current Period Rate -> To Period @ Current Rate.
            else if (
                firstReducedRatePeriod >= previousPeriodRate.effectiveFromPeriod
                    && toPeriod >= currentPeriodRate.effectiveFromPeriod
            ) {
                //  FRRP -> Current Period - 1 @ Previous Rate +
                yield += _calcInterest(
                    context,
                    principal,
                    (currentPeriodRate.effectiveFromPeriod - 1) - firstReducedRatePeriod,
                    previousPeriodRate.interestRate
                );

                //  Current Period -> To Period @ Current Rate.
                yield += _calcInterest(
                    context,
                    principal,
                    (toPeriod - currentPeriodRate.effectiveFromPeriod) + 1,
                    currentPeriodRate.interestRate
                );
            }
            // Timeline: 1st Reduced Rate Period -> Previous Period Rate -> Current Period Rate -> To Period
            // If the FRRP is before the previous Period Rate, then we have what should be an impossible operational
            // scenario. We cannot determine what Interest Rate to apply, because we would have to track the Period Rate
            // before the Previous Period Rate, which is not within the scope of this realisation. Also, historical
            // calculations are not supported.
            else {
                revert TripleRateYieldStrategy_DepositPeriodOutsideInterestRatePeriodRange(
                    firstReducedRatePeriod,
                    previousPeriodRate.effectiveFromPeriod,
                    currentPeriodRate.effectiveFromPeriod
                );
            }
        }
    }

    /**
     * @inheritdoc YieldStrategy
     */
    function calcPrice(address contextContract, uint256 periodsElapsed) public view override returns (uint256 price) {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        ITripleRateContext context = ITripleRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            periodsElapsed, context.rateScaled(), context.frequency(), context.scale()
        );
    }

    /**
     * @notice Calculates the number of 'full' Interest Rate Periods.
     *
     * @param noOfPeriodsForFullRate_  The number of periods that apply for the 'full' Interest Rate.
     * @param from_ The from period
     * @param to_ The to period
     * @return The calculated number of 'full' Interest Rate Periods.
     */
    function _noOfFullRatePeriods(uint256 noOfPeriodsForFullRate_, uint256 from_, uint256 to_)
        internal
        view
        virtual
        returns (uint256)
    {
        (uint256 noOfPeriods,,) = periodRangeFor(from_, to_);
        return noOfPeriods - (noOfPeriods % noOfPeriodsForFullRate_);
    }

    /**
     * @notice Calculates the first 'reduced' Interest Rate Period after the `_from` period.
     * @dev Encapsulates the algorithm that determines the first 'reduced' Interest Rate Period. The calculation,
     *  IFF there are 'full' Interest Rate periods, is: `from_` + `noOfFullRatePeriods_`
     *  Otherwise, it is simply the `from_` value.
     *
     * @param noOfFullRatePeriods_  The number of Full Rate Periods
     * @param from_  The from period.
     * @return The calculated first Reduced Rate Period.
     */
    function _firstReducedRatePeriod(uint256 noOfFullRatePeriods_, uint256 from_)
        internal
        pure
        virtual
        returns (uint256)
    {
        return noOfFullRatePeriods_ != 0 ? from_ + noOfFullRatePeriods_ : from_;
    }

    /// @dev Internal convenience function for calculating interest based on a context.
    function _calcInterest(ITripleRateContext context, uint256 principal_, uint256 noOfPeriods_, uint256 rate_)
        private
        view
        returns (uint256 interest_)
    {
        return CalcSimpleInterest.calcInterest(principal_, rate_, noOfPeriods_, context.frequency(), context.scale());
    }

    /// @dev Internal convenience function for calculating interest based on a context.
    function _calcInterest(ITripleRateContext context, uint256 principal_, uint256 noOfPeriods_)
        private
        view
        returns (uint256 interest_)
    {
        return _calcInterest(context, principal_, noOfPeriods_, context.rateScaled());
    }
}
