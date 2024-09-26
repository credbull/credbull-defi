// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IYieldStrategy
 * @dev Interface for calculating yield and price based on principal and elapsed time periods.
 */
interface IYieldStrategy {
    /// @notice When the `contextContract` parameter is invalid.
    error IYieldStrategy_InvalidContextAddress();
    /// @notice When the `fromPeriod` and `toPeriod` parameters do not form a valid range.
    error IYieldStrategy_InvalidPeriodRange(uint256 from, uint256 to);

    /**
     * @notice Returns the yield for `principal` over the time period from `fromTimePeriod` to `toTimePeriod`.
     * @dev Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.
     *  Reverts with [IYieldStrategy_InvalidPeriodRange] if the `fromTimePeriod` and `toTimePeriod` do not form a valid
     * Period Range.
     *
     * @param contextContract The [address] of the contract providing additional data required for the calculation.
     * @param principal The principal amount to calculate the yield for.
     * @param fromTimePeriod The period, inclusive, at the start of the Period Range.
     * @param toTimePeriod The period, inclusive, at the end of the Period Range.
     * @return yield The calculated yeild.
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
        external
        view
        returns (uint256 yield);

    /**
     * @notice Returns the price after `numTimePeriodsElapsed`.
     * @dev Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.
     *
     * @param contextContract The [address] of the contract providing additional data required for the calculation.
     * @param numTimePeriodsElapsed The number of Time Periods that have elapsed at the current time.
     * @return price The calculated Price.
     */
    function calcPrice(address contextContract, uint256 numTimePeriodsElapsed) external view returns (uint256 price);
}
