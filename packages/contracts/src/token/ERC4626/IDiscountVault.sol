// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @dev A vault using Principal and Discounting for asset and shares respectively.
 */
interface IDiscountVault is IERC4626 {
    /// @notice Calculates the yield for `principal` and to `toPeriod`.
    function calcYield(uint256 principal, uint256 toPeriod) external view returns (uint256 yield);

    /// @notice Calculates the yield for `principal` from `fromPeriod` to `toPeriod`.
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) external view returns (uint256 yield);

    /// @notice Calculates price for a given `numPeriodsElapsed`
    function calcPrice(uint256 numPeriodsElapsed) external view returns (uint256 price);

    /// @notice Gets the vault's tenor
    function getTenor() external view returns (uint256 tenor);

    /// @notice Gets the current number of time periods elapsed
    function currentPeriodsElapsed() external view returns (uint256 currentPeriodsElapsed_);
}
