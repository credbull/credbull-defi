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
     * @dev See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        returns (uint256 yield)
    {
        IDualRateContext context = IDualRateContext(contextContract);

        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        uint256 interestRate =
            numPeriodsElapsed == context.periodsForFullRate() ? context.fullRate() : context.reducedRate();

        return CalcSimpleInterest.calcInterest(principal, interestRate, numPeriodsElapsed, context.frequency());
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
}
