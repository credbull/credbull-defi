// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @dev A vault using Principal and Discounting for asset and shares respectively.
 */
interface IDiscountVault is IERC4626 {
    /// @notice Calculates yield using `principal` and `numTimePeriodsElapsed`
    function calcYield(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 yield);

    /// @notice Calculates price for a given `numTimePeriodsElapsed`
    function calcPrice(uint256 numTimePeriodsElapsed) external view returns (uint256 price);

    /// @notice Converts `assets` to shares at a given `numTimePeriodsElapsed`
    function convertToSharesAtPeriod(uint256 assets, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 shares);

    /// @notice Converts `shares` to assets at a given `numTimePeriodsElapsed`
    function convertToAssetsAtPeriod(uint256 shares, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 assets);

    /// @notice Gets the vault's tenor
    function getTenor() external view returns (uint256 tenor);

    /// @notice Gets the current number of time periods elapsed
    function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

    /// @notice Sets `currentTimePeriodsElapsed` for testing purposes
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
