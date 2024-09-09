// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ITimelock {


  /**
   * @dev Error thrown when attempting to unlock tokens before the lock period has expired.
   * @param currentPeriod The current time or period.
   * @param lockReleasePeriod The required time or period that must be reached to unlock the tokens.
   */
  error LockDurationNotExpired(address account, uint256 currentPeriod, uint256 lockReleasePeriod);

  error InsufficientLockedBalanceAtPeriod(address account, uint256 available, uint256 required, uint256 lockReleasePeriod);

  /**
   * @dev Locks a specified amount of tokens for a particular account until a given release period.
   * @param account The address of the account whose tokens are to be locked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param amount The amount of tokens to be locked.
   */
  function lock(address account, uint256 lockReleasePeriod, uint256 amount) external;

  /**
   * @dev Unlocks a specified amount of tokens for a particular account for a given release period.
   * @param account The address of the account whose tokens are to be unlocked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param amount The amount of tokens to be unlocked.
   */
  function unlock(address account, uint256 lockReleasePeriod, uint256 amount) external;

  /**
   * @dev Returns the amount of tokens currently locked for a specific account and release period.
   * @param account The address of the account whose tokens are locked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @return amountLocked The amount of tokens locked for the given account and release period.
   */
  function getLockedAmount(address account, uint256 lockReleasePeriod) external view returns (uint256 amountLocked);

  /**
   * @dev Returns the amount of tokens that could be unlocked for the specific account and release period
   * @param account The address of the account whose tokens are unlocked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @return amountUnlockable The amount of tokens that could be unlocked for the given account.
   */
  function previewUnlock(address account, uint256 lockReleasePeriod) external view returns (uint256 amountUnlockable);


  /**
   * @dev Returns lock periods for a given account where the account has a non-zero balance.
   * @param account The address of the account whose lock periods are to be retrieved.
   * @return lockPeriods An array of uint256 values representing the periods during which the account has locked tokens.
   */
  function getLockPeriods(address account) external view returns (uint256 [] memory lockPeriods);

}
