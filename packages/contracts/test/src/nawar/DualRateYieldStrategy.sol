// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IDualRateContext } from "@credbull/interest/IDualRateContext.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

/**
 * @title DualRateYieldStrategy
 * @dev A yield strategy that calculates returns using different interest rates based on the holding period.
 *      If the holding period exceeds a certain threshold (full period), the full rate is applied.
 *      Otherwise, a reduced rate is used for shorter periods.
 */
contract DualRateYieldStrategy is IYieldStrategy {
    /**
     * @notice Calculates the yield for a given principal over a range of periods.
     * @param contextContract The address of the contract that provides rate and period context.
     * @param principal The principal amount deposited.
     * @param fromPeriod The period in which the deposit was made (start period).
     * @param toPeriod The period in which redemption occurs (end period).
     * @return yield The calculated yield based on applying both full and partial rates over the relevant periods.
     *
     * @dev The yield is calculated by first determining the number of full periods that have passed
     *      and applying the full interest rate. For any remaining partial periods, a reduced interest rate is applied.
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        returns (uint256 yield)
    {
        // Retrieve context data from the DualRateContext contract
        IDualRateContext context = IDualRateContext(contextContract);

        uint256 reducedRateScaled = context.reducedRateScaled();

        // Calculate the number of full periods that have elapsed
        uint256 numOfPeriodsElapsed =
            ((toPeriod - fromPeriod) / context.numPeriodsForFullRate()) * context.numPeriodsForFullRate();

        // Calculate the number of partial periods that have elapsed
        uint256 numOfPartialsElapsed = (toPeriod - fromPeriod) % context.numPeriodsForFullRate();

        // Calculate the yield for the full periods using the full interest rate
        uint256 fullYield = CalcSimpleInterest.calcInterest(
            principal, context.fullRateScaled(), numOfPeriodsElapsed, context.frequency(), context.scale()
        );

        // Calculate the yield for the partial periods using the reduced interest rate
        uint256 partialYield = CalcSimpleInterest.calcInterest(
            principal, reducedRateScaled, numOfPartialsElapsed, context.frequency(), context.scale()
        );

        // Return the total yield (sum of full and partial yields)
        return fullYield + partialYield;
    }

    /**
     * @notice Calculates the price for a given number of periods that have elapsed, based on the full interest rate.
     * @param contextContract The address of the contract providing rate and period context.
     * @param numPeriodsElapsed The number of periods that have elapsed.
     * @return price The calculated price based on the interest rate and the number of periods elapsed.
     *
     * @dev The price is calculated using the full interest rate, the frequency, and a scaling factor.
     *      This can be used to determine the discounted price for a deposit or similar financial products.
     */
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        virtual
        returns (uint256 price)
    {
        // Retrieve context data from the DualRateContext contract
        IDualRateContext context = IDualRateContext(contextContract);

        // Calculate the price based on the number of periods, interest rate, and frequency
        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, context.fullRateScaled(), context.frequency(), context.scale()
        );
    }
}
