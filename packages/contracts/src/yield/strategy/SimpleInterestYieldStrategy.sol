// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { YieldStrategy } from "@credbull/yield/strategy/YieldStrategy.sol";

/**
 * @title SimpleInterestYieldStrategy
 * @dev Strategy where returns are calculated using SimpleInterest
 */
contract SimpleInterestYieldStrategy is YieldStrategy {
    constructor(RangeInclusion rangeInclusion_) YieldStrategy(rangeInclusion_) { }

    /// @dev See {CalcSimpleInterest-calcInterest}
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
        ICalcInterestMetadata interestData = ICalcInterestMetadata(contextContract);

        return CalcSimpleInterest.calcInterest(
            principal, interestData.rateScaled(), periodsElapsed, interestData.frequency(), interestData.scale()
        );
    }

    /// @dev See {CalcSimpleInterest-calcPriceFromInterest}
    function calcPrice(address contextContract, uint256 periodsElapsed) public view override returns (uint256 price) {
        if (address(0) == contextContract) {
            revert IYieldStrategy_InvalidContextAddress();
        }
        ICalcInterestMetadata interestData = ICalcInterestMetadata(contextContract);

        return CalcSimpleInterest.calcPriceFromInterest(
            interestData.rateScaled(), periodsElapsed, interestData.frequency(), interestData.scale()
        );
    }
}
