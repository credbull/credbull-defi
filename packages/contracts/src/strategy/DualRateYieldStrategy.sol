// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IDualRateContext } from "@credbull/interest/IDualRateContext.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

/**
 * @title DualRateYieldStrategy
 * @dev Calculates returns using different rates depending on the holding period
 */
contract DualRateYieldStrategy is IYieldStrategy {
    /**
     * @notice Calculates the yield on a principal over a given period.
     * @param contextContract Address of the contract implementing IDualRateContext.
     * @param principal Principal amount for yield calculation.
     * @param fromPeriod Starting period for interest.
     * @param toPeriod Ending period for interest.
     * @return yield Total yield using full and reduced rates.
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        returns (uint256 yield)
    {
        IDualRateContext context = IDualRateContext(contextContract);

        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        // calc interest for the fullRate periods
        uint256 numFullRatePeriodsElapsed =
            _numFullRatePeriodsElapsed(context.numPeriodsForFullRate(), numPeriodsElapsed);
        uint256 fullRateInterest = CalcSimpleInterest.calcInterest(
            principal, context.fullRateScaled(), numFullRatePeriodsElapsed, context.frequency(), context.scale()
        );

        // now calc interest for the reduceRate periods
        uint256 numReducedRatePeriodsElapsed = numPeriodsElapsed - numFullRatePeriodsElapsed;
        uint256 reducedRateInterest = CalcSimpleInterest.calcInterest(
            principal, context.reducedRateScaled(), numReducedRatePeriodsElapsed, context.frequency(), context.scale()
        );

        return fullRateInterest + reducedRateInterest;
    }

    /**
     * @notice Calculates price based on elapsed periods and full rate.
     * @param contextContract Address of the contract implementing IDualRateContext.
     * @param numPeriodsElapsed Number of periods elapsed.
     * @return price Price calculated using full rate.
     */
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        virtual
        returns (uint256 price)
    {
        IDualRateContext context = IDualRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.fullRateScaled(), context.frequency(), context.scale()
        );
    }

    /**
     * @notice Returns the number of full-rate periods elapsed.
     * @param tenor Required periods for full rate.
     * @param numPeriodsElapsed Total elapsed periods.
     * @return numFullRatePeriodsElapsed Number of full-rate periods.
     */
    function _numFullRatePeriodsElapsed(uint256 tenor, uint256 numPeriodsElapsed)
        internal
        pure
        returns (uint256 numFullRatePeriodsElapsed)
    {
        uint256 numFullRatePeriods = numPeriodsElapsed / tenor; // integer division - will only get "whole" fullPeriods

        return numFullRatePeriods * tenor;
    }
}
