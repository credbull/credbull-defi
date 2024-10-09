// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { AbstractYieldStrategy } from "@credbull/yield/strategy/AbstractYieldStrategy.sol";

/**
 * @title TripleRateYieldStrategy
 * @dev Calculates returns using 1 'full' rate and 2 'reduced' rates, applied according to the Tenor Period, and
 *  depending on the holding period.
 */
contract TripleRateYieldStrategy is AbstractYieldStrategy {
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
     * @inheritdoc AbstractYieldStrategy
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
        if (fromPeriod > toPeriod) {
            revert IYieldStrategy_InvalidPeriodRange(fromPeriod, toPeriod);
        }

        // On deposit day, when not inclusive, there is no yield.
        if (fromPeriod == toPeriod) {
            return 0;
        }

        ITripleRateContext context = ITripleRateContext(contextContract);

        // Calculate interest for full-rate periods
        uint256 noOfFullRatePeriods = _noOfFullRatePeriods(context.numPeriodsForFullRate(), fromPeriod, toPeriod);
        if (noOfFullRatePeriods > 0) {
            yield = CalcSimpleInterest.calcInterest(
                principal, context.rateScaled(), noOfFullRatePeriods, context.frequency(), context.scale()
            );
        }

        // Calculate interest for reduced-rate periods
        if (_noOfPeriods(fromPeriod, toPeriod) - noOfFullRatePeriods > 0) {
            uint256 firstReducedRatePeriod = _firstReducedRatePeriod(noOfFullRatePeriods, fromPeriod);
            ITripleRateContext.PeriodRate memory currentPeriodRate = context.currentPeriodRate();
            ITripleRateContext.PeriodRate memory previousPeriodRate = context.previousPeriodRate();

            // Timeline: Previous Period Rate -> Current Period Rate -> 1st Reduced Rate Period -> To Period
            // If the first 'reduced' interest rate period (FRRP) is on or after the current Period Rate, then the
            // 'reduced' Yield is:
            //  (FRRP -> To Period) @ Current Rate.
            if (firstReducedRatePeriod >= currentPeriodRate.effectiveFromPeriod) {
                //  1st RR Period -> To Period @ Current Rate.
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    currentPeriodRate.interestRate,
                    toPeriod - firstReducedRatePeriod,
                    context.frequency(),
                    context.scale()
                );
            }
            // Timeline: Previous Period Rate -> 1st Reduced Rate Period -> Current Period Rate -> To Period
            // If the FRRP is on or after the previous Period Rate, then the 'reduced' Yield is:
            //  (FRRP -> Current Period Rate - 1) @ Previous Rate +
            //  (Current Period Rate -> To Period) @ Current Rate.
            // The '- 1' is because the Previous Period Rate applies up to but exclusive of the Current Period Rate.
            else if (firstReducedRatePeriod >= previousPeriodRate.effectiveFromPeriod) {
                //  1st RR Period -> Current Period @ Previous Rate +
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    previousPeriodRate.interestRate,
                    (currentPeriodRate.effectiveFromPeriod - firstReducedRatePeriod) - 1,
                    context.frequency(),
                    context.scale()
                );

                //  Current Period -> To Period @ Current Rate.
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    currentPeriodRate.interestRate,
                    (toPeriod - currentPeriodRate.effectiveFromPeriod) + 1,
                    context.frequency(),
                    context.scale()
                );
            }
            // Timeline: 1st Reduced Rate Period -> Previous Period Rate -> Current Period Rate -> To Period
            // If the FRRP is before the previous Period Rate, then we have what should be an impossible operational
            // scenario. We cannot determine what Rate to apply, because we would have to track the Period Rate before
            // the Previous Period Rate, which is not within the scope of this realisation.
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
     * @inheritdoc AbstractYieldStrategy
     */
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        override
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
     * @notice Calculates the number of 'full' Interest Rate Periods.
     *
     * @param noOfPeriodsForFullRate_  The number of periods that apply for the 'full' Interest Rate.
     * @param from_ The from period
     * @param to_ The to period
     * @return The calculated number of 'full' Interest Rate Periods.
     */
    function _noOfFullRatePeriods(uint256 noOfPeriodsForFullRate_, uint256 from_, uint256 to_)
        internal
        pure
        virtual
        returns (uint256)
    {
        uint256 _periods = _noOfPeriods(from_, to_);
        return _periods - (_periods % noOfPeriodsForFullRate_);
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
}
