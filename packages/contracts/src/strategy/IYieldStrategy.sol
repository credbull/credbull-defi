// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IYieldStrategy Interface
 * @dev Interface for calculating yield and price based on principal and elapsed time periods.
 * Used by Vault and Vault-like contracts where returns are accrued over time.
 */
interface IYieldStrategy {
    /**
     * @notice Calculates the yield based on the principal and elapsed time periods.
     * @param contextContract The contract with any required "context" (e.g. input data)
     * @param principal The principal amount
     * @param fromTimePeriod The start period for calculating yield
     * @param toTimePeriod The end period for calculating yield
     * @return yield The yield.
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
        external
        view
        returns (uint256 yield);

    /**
     * @notice Calculates the price for a given number of periods elapsed.
     * @param contextContract The contract with any required "context" (e.g. input data)
     * @param numTimePeriodsElapsed The number of time periods that have elapsed.
     * @return price The price
     */
    function calcPrice(address contextContract, uint256 numTimePeriodsElapsed) external view returns (uint256 price);
}
