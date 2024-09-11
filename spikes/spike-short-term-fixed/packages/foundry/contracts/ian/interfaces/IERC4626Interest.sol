// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ICalcDiscounted } from "@credbull-spike/contracts/ian/interfaces/ICalcDiscounted.sol";

/**
 * @dev Extension to Interface Vault Standard
 */
interface IERC4626Interest is IERC4626, ICalcDiscounted {
  function convertToSharesAtPeriod(
    uint256 assets,
    uint256 numTimePeriodsElapsed
  ) external view returns (uint256 shares);

  function convertToAssetsAtPeriod(
    uint256 shares,
    uint256 numTimePeriodsElapsed
  ) external view returns (uint256 assets);

  // TODO - confirm if required on interface
  function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

  // TODO - confirm if required on interface
  function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;

  // TODO - confirm if required on interface
  function getTenor() external view returns (uint256 tenor);
}
