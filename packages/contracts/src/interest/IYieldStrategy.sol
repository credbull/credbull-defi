// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

/**
 * @title IYieldStrategy Interface
 * @dev Interface for calculating yield and price based on elapsed time periods.
 * Used by Vault contracts (or similar) where returns are accrued over time.
 */
interface IYieldStrategy {
    /**
     * @notice Calculates the yield based on the principal and elapsed time periods.
     * @param dataContract The contract with any data required for the calculation.
     * @param principal The initial principal amount.
     * @param fromTimePeriod The start period for calculating yield
     * @param toTimePeriod The end period for calculating yield
     * @return yield The calculated yield amount.
     */
    function calcYield(address dataContract, uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
        external
        view
        returns (uint256 yield);

    /**
     * @notice Calculates the price for a given number of periods elapsed.
     * @param dataContract The contract with any data required for the calculation.
     * @param numTimePeriodsElapsed The number of time periods that have elapsed.
     * @return price The price
     */
    function calcPrice(address dataContract, uint256 numTimePeriodsElapsed) external view returns (uint256 price);
}
