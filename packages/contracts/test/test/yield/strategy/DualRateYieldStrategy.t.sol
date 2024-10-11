// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { YieldStrategy } from "@credbull/yield/strategy/YieldStrategy.sol";

import { IDualRateContext } from "@test/test/yield/context/IDualRateContext.t.sol";

/**
 * @title DualRateYieldStrategy
 * @dev Calculates returns using different rates depending on the holding period.
 */
contract DualRateYieldStrategy is YieldStrategy {
    constructor(RangeInclusion rangeInclusion_) YieldStrategy(rangeInclusion_) { }

    /// @notice Returns the yield for `principal` from `fromPeriod` to `toPeriod` using full and reduced rates.
    /// @param contextContract The contract with the data calculating the yield
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        override
        returns (uint256 yield)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }

        (uint256 periodsElapsed,,) = periodRangeFor(fromPeriod, toPeriod);
        IDualRateContext context = IDualRateContext(contextContract);

        // Calculate interest for full-rate periods
        uint256 numFullRatePeriodsElapsed = _numFullRatePeriodsElapsed(context.numPeriodsForFullRate(), periodsElapsed);
        uint256 fullRateInterest = CalcSimpleInterest.calcInterest(
            principal, context.rateScaled(), numFullRatePeriodsElapsed, context.frequency(), context.scale()
        );

        // Calculate interest for reduced-rate periods
        uint256 numReducedRatePeriodsElapsed = periodsElapsed - numFullRatePeriodsElapsed;
        uint256 reducedRateInterest = CalcSimpleInterest.calcInterest(
            principal, context.reducedRateScaled(), numReducedRatePeriodsElapsed, context.frequency(), context.scale()
        );

        return fullRateInterest + reducedRateInterest;
    }

    /// @notice Returns the price after `numPeriodsElapsed` using the full rate.
    /// @param contextContract The contract with the data calculating the price
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        override
        returns (uint256 price)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        IDualRateContext context = IDualRateContext(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.rateScaled(), context.frequency(), context.scale()
        );
    }

    /// @notice Returns the number of full-rate periods elapsed.
    function _numFullRatePeriodsElapsed(uint256 tenor, uint256 numPeriodsElapsed)
        internal
        pure
        returns (uint256 numFullRatePeriodsElapsed)
    {
        uint256 numFullRatePeriods = numPeriodsElapsed / tenor; // integer division returns whole full periods
        return numFullRatePeriods * tenor;
    }
}
