// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

/**
 * @title MultipleRateYieldStrategy
 * @dev Calculates returns using different rates depending on the holding period.
 */
abstract contract AbstractYieldStrategy is IYieldStrategy {
    /**
     * @dev Utility function to calculate the Number Of Periods between `from_` and `to_`. Also reduces Stack Depth in
     *  invoking functions.
     *
     * @param from_ The from period
     * @param to_ The to period
     */
    function _noOfPeriods(uint256 from_, uint256 to_) internal pure returns (uint256) {
        return to_ - from_;
    }

    /**
     * @dev Calculates the number of Full Rate Periods.
     *
     * @param _noOfPeriodsForFullRate  The number of periods that apply for Full Rate.
     * @param _from The from period
     * @param _to The to period
     * @return The calculated number of Full Rate Periods.
     */
    function _noOfFullRatePeriods(uint256 _noOfPeriodsForFullRate, uint256 _from, uint256 _to)
        internal
        pure
        returns (uint256)
    {
        uint256 _periods = _noOfPeriods(_from, _to);
        return _periods - (_periods % _noOfPeriodsForFullRate);
    }

    /**
     * @dev Calculates the first Reduced Rate Period.
     *
     * @param noOfFullRatePeriods_  The number of Full Rate Periods
     * @param _from  The from period.
     * @return The calculated first Reduced Rate Period.
     */
    function _firstReducedRatePeriod(uint256 noOfFullRatePeriods_, uint256 _from) internal pure returns (uint256) {
        return noOfFullRatePeriods_ != 0 ? _from + noOfFullRatePeriods_ : _from;
    }
}
