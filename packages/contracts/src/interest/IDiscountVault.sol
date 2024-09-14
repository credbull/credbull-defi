// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

/**
 * @dev A vault that using Principal and Discounting for asset and shares respectively
 */
interface IDiscountVault {
    /**
     * @notice Calculates the yield based on the principal and elapsed time periods.
     * @param principal The initial principal amount.
     * @param fromTimePeriod The start period for calculating yield
     * @param toTimePeriod The end period for calculating yield
     * @return yield The calculated yield amount.
     */
    function calcYield(uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
        external
        view
        returns (uint256 yield);

    /**
     * @notice Calculates the price for a given number of periods elapsed.
     * @param numTimePeriodsElapsed The number of time periods that have elapsed.
     * @return price The price
     */
    function calcPrice(uint256 numTimePeriodsElapsed) external view returns (uint256 price);
}
