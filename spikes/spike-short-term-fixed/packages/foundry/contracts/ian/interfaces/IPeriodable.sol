// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPeriodable {

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
