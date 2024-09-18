// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

/**
 * @title SimpleInterestYieldStrategy
 * @dev Strategy that used SimpleInterest to calculate returns
 */
contract SimpleInterestYieldStrategy is IYieldStrategy {
    /**
     * @dev See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        returns (uint256 yield)
    {
        ICalcInterestMetadata interestData = ICalcInterestMetadata(contextContract);

        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        return CalcSimpleInterest.calcInterest(
            principal, interestData.interestRate(), numPeriodsElapsed, interestData.frequency(), interestData.scale()
        );
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
        ICalcInterestMetadata interestData = ICalcInterestMetadata(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            interestData.interestRate(), numPeriodsElapsed, interestData.frequency(), interestData.scale()
        );
    }
}
