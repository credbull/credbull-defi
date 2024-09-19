// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IYieldStrategy
 * @dev Interface for calculating yield and price based on principal and elapsed time periods.
 */
interface IYieldStrategy {
    /// @notice Returns the yield for `principal` over the time period from `fromTimePeriod` to `toTimePeriod`.
    /// @param contextContract The contract providing additional data required for the calculation.
    function calcYield(address contextContract, uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
        external
        view
        returns (uint256 yield);

    /// @notice Returns the price after `numTimePeriodsElapsed`.
    /// @param contextContract The contract providing additional data required for the calculation.
    function calcPrice(address contextContract, uint256 numTimePeriodsElapsed) external view returns (uint256 price);
}
