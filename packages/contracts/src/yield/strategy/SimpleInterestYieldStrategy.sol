// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

/**
 * @title SimpleInterestYieldStrategy
 * @dev Strategy where returns are calculated using SimpleInterest
 */
contract SimpleInterestYieldStrategy is IYieldStrategy {
    /// @dev See {CalcSimpleInterest-calcInterest}
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
        ICalcInterestMetadata interestData = ICalcInterestMetadata(contextContract);

        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        return CalcSimpleInterest.calcInterest(
            principal, interestData.rateScaled(), numPeriodsElapsed, interestData.frequency(), interestData.scale()
        );
    }

    /// @dev See {CalcSimpleInterest-calcPriceFromInterest}
    function calcPrice(address contextContract, uint256 numPeriodsElapsed)
        public
        view
        virtual
        returns (uint256 price)
    {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        ICalcInterestMetadata interestData = ICalcInterestMetadata(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            interestData.rateScaled(), numPeriodsElapsed, interestData.frequency(), interestData.scale()
        );
    }
}
