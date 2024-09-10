// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRollable {
  /**
   * @dev Rolls over a specified amount of tokens for another lock period.
   * MUST revert if there aren't sufficient tokens eligible for rollover
   * implementing functions SHOULD perform any "unlocks" prior to rollover (or equivalent)
   * @param account The address of the account whose tokens are to be rolled over.
   * @param lockReleasePeriod The new period during which these tokens will be locked.
   * @param value The amount of tokens to be rolled over and locked for the new period.
   *
   */
  function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) external;

  /**
   * @dev Calculates any "bonus" for retained assets for another period
   * @param account The address of the account whose tokens are to be rolled over.
   * @param lockReleasePeriod The new period during which these tokens will be locked.
   * @param value The amount of tokens to be rolled over and eligible for bonus
   * @return rolloverBonus The amount of tokens given as bonus for rolling over
   */
  function calcRolloverBonus(
    address account,
    uint256 lockReleasePeriod,
    uint256 value
  ) external returns (uint256 rolloverBonus);
}
