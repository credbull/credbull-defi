// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IYieldStrategy } from "@credbull/interest/IYieldStrategy.sol";

/**
 * @title SimpleInterestYieldStrategy
 * @dev Strategy that used SimpleInterest to calculate returns
 */
abstract contract SimpleInterestYieldStrategy is IYieldStrategy, ICalcInterestMetadata {
    /**
     * @dev See {CalcDiscounted-calcPriceFromInterest}
     */
    function calcPrice(uint256 numPeriodsElapsed) public view virtual returns (uint256 price) {
        return CalcSimpleInterest.calcPriceFromInterest(
            numPeriodsElapsed, getInterestInPercentage(), getFrequency(), getScale()
        );
    }

    /**
     * @dev See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        override
        returns (uint256 yield)
    {
        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        return CalcSimpleInterest.calcInterest(principal, numPeriodsElapsed, getInterestInPercentage(), getFrequency());
    }

    function getFrequency() public view virtual returns (uint256 frequency);

    function getInterestInPercentage() public view virtual returns (uint256 interestRateInPercentage);

    function getScale() public view virtual returns (uint256 scale);
}
