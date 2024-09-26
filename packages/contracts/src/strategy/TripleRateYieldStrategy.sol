// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITripleRateContext } from "@credbull/interest/context/ITripleRateContext.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { AbstractYieldStrategy } from "@credbull/strategy/AbstractYieldStrategy.sol";

/**
 * @title DualRateYieldStrategy
 * @dev Calculates returns using different rates depending on the holding period.
 */
contract TripleRateYieldStrategy is AbstractYieldStrategy {
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
            (uint256 currentTenorPeriod, uint256 currentReducedRate) = context.currentTenorPeriodAndRate();

            // Previous Tenor Period ... Current Tenor Period ... 1st Reduced Rate Period ... To Period
            // If the 1st RR Period is on or after the current Tenor Period, then RR Interest is:
            //  1st RR Period -> To Period @ Current Rate.
            if (firstReducedRatePeriod >= currentTenorPeriod) {
                //  1st RR Period -> To Period @ Current Rate.
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    currentReducedRate,
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
                ( /*uint256 previousTenorPeriod*/ , uint256 previousReducedRate) = context.previousTenorPeriodAndRate();

                //  1st RR Period -> Current Period @ Previous Rate +
                yield += CalcSimpleInterest.calcInterest(
                    principal,
                    previousReducedRate,
                    currentTenorPeriod - firstReducedRatePeriod,
                    context.frequency(),
                    context.scale()
                );

                //  Current Period -> To Period @ Current Rate.
                yield += CalcSimpleInterest.calcInterest(
                    principal, currentReducedRate, toPeriod - currentTenorPeriod, context.frequency(), context.scale()
                );
            }
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
        ITripleRateContext context = ITripleRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.rateScaled(), context.frequency(), context.scale()
        );
    }
}
