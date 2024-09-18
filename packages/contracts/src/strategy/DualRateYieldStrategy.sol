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
     *
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        returns (uint256 yield)
    {
        IDualRateContext context = IDualRateContext(contextContract);

        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        uint256 fullRatePeriodsElapsed = _fullRatePeriodsElapsed(context.periodsForFullRate(), numPeriodsElapsed);

        uint256 fullRateInterest =
            CalcSimpleInterest.calcInterest(principal, context.fullRate(), fullRatePeriodsElapsed, context.frequency());

        uint256 reducedRatePeriodsElapsed = numPeriodsElapsed - fullRatePeriodsElapsed;
        uint256 reducedRateInterest = CalcSimpleInterest.calcInterest(
            principal, context.reducedRate(), reducedRatePeriodsElapsed, context.frequency()
        );

        return fullRateInterest + reducedRateInterest;
    }

    /**
     * @dev See {CalcDiscounted-calcPriceFromInterest}
     */
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        virtual
        returns (uint256 price)
    {
        IDualRateContext context = IDualRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.fullRate(), context.frequency(), context.scale()
        );
    }

    /**
     * @dev See {CalcDiscounted-calcPriceFromInterest}
     */
    function _fullRatePeriodsElapsed(uint256 periodsForFullRate, uint256 numPeriodsElapsed)
        internal
        view
        returns (uint256 _fullRatePeriodsElapsed)
    {
        uint256 fullRatePeriods = numPeriodsElapsed / periodsForFullRate; // integer division - will only get "whole" fullPeriods

        return fullRatePeriods * periodsForFullRate;
    }
}
