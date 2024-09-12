// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull-contracts/contracts/interest/ICalcInterestMetadata.sol";

interface IProduct is ICalcInterestMetadata {

  error RedeemTimePeriodNotSupported(uint256 currentPeriod, uint256 redeemPeriod);

  // ===============  Vault / Vault-like Behavior ===============

  /**
   * @notice Deposits a specified amount of assets and returns the corresponding number of shares to the receiver.
   * @dev This function is similar to the ERC-4626 standard deposit function.
   * @param assets The amount of assets to deposit.
   * @param receiver The address that will receive the minted shares.
   * @return shares The number of shares minted to the receiver.
   */
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  /**
   * @notice Redeems a specified amount of shares for the corresponding amount of assets.
   * @dev This function is similar to the ERC-4626 standard redeem function.
   * @param shares The number of shares to redeem.
   * @param receiver The address that will receive the redeemed assets.
   * @param owner The address of the owner of the shares to be redeemed.
   * @return assets The amount of assets returned to the receiver.
   */
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

  /**
   * @notice Redeems shares for assets based on a specific time period that has elapsed since deposit.
   * @dev Allows redemption of shares for the assets they represent at a specific time period, adjusting for interest accrued.
   * @param shares The number of shares to redeem.
   * @param receiver The address that will receive the redeemed assets.
   * @param owner The address of the owner of the shares to be redeemed.
   * @param redeemTimePeriod The time period for redeem
   * @return assets The amount of assets returned to the receiver based on the elapsed period.
   */
  function redeemAtPeriod(
    uint256 shares,
    address receiver,
    address owner,
    uint256 redeemTimePeriod
  ) external returns (uint256 assets);

  /**
   * @notice Returns the interest accrued for this account for the given depositTimePeriod
   * e.g. if Alice deposits on Day 1 and Day 2, this will ONLY return the interest for the Day 1 deposit
   * @param account The address of the user.
   * @param depositTimePeriod The time period to calculate for
   * @return The amount of interest accrued by the user for the given depositTimePeriod
   */
  function calcInterestForDepositTimePeriod(address account, uint256 depositTimePeriod) external view returns (uint256);

  /**
   * @notice Returns the total interest accrued by a user across ALL deposit time periods
   * @param account The address of the user.
   * @return The total amount of interest earned by the user.
   */
  function calcTotalInterest(address account) external view returns (uint256);

  /**
   * @notice Returns the total amount of assets deposited by a user.
   * @param account The address of the user.
   * @return The total amount of assets deposited by the user.
   */
  function calcTotalDeposits(address account) external view returns (uint256);

  // =============== Testing Purposes Only ===============

  /**
   * @notice Sets the current number of time periods elapsed.
   * @dev This function is intended for testing purposes to simulate the passage of time.
   * @param currentTimePeriodsElapsed The number of time periods to set as elapsed.
   */
  function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;

}
