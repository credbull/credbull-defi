// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @dev A vault that using Principal and Discounting for asset and shares respectively
 */
interface IDiscountVault is IERC4626 {
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

    function convertToSharesAtPeriod(uint256 assets, uint256 depositTimePeriod)
        external
        view
        returns (uint256 shares);

    function convertToAssetsForPeriods(uint256 shares, uint256 depositTimePeriod, uint256 redeemTimePeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Gets the current number of time periods elapsed.
     * @return currentTimePeriodsElapsed The number of time periods elapsed.
     */
    function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

    // =============== Testing Purposes Only ===============

    /**
     * @notice Sets the current number of time periods elapsed.
     * @dev This function is intended for testing purposes to simulate the passage of time.
     * @param currentTimePeriodsElapsed The number of time periods to set as elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
