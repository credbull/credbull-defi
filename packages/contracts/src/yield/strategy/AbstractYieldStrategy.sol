// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

/**
 * @title AbstractYieldStrategy
 * @dev Interface for calculating yield and price based on principal and elapsed time periods.
 */
abstract contract AbstractYieldStrategy is IYieldStrategy {
    /**
     * @inheritdoc IYieldStrategy
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
        external
        view
        virtual
        returns (uint256 yield);

    /**
     * @inheritdoc IYieldStrategy
     */
    function calcPrice(address contextContract, uint256 numTimePeriodsElapsed)
        external
        view
        virtual
        returns (uint256 price);

    /**
     * @notice Calculate the number of periods in effect for Yield Calculation.
     * @dev Encapsulates the algorithm for determining the number of periods to calculate yield with. The calculation is:
     *      noOfPeriods = (`to_` - `from_`)
     *
     * @param from_ The from period
     * @param to_ The to period
     * @return noOfPeriods_ The calculated effective number of periods.
     */
    function _noOfPeriods(uint256 from_, uint256 to_) internal pure virtual returns (uint256 noOfPeriods_) {
        return to_ - from_;
    }
}
