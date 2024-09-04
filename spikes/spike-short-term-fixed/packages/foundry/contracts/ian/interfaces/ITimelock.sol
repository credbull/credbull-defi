// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ITimelock {
    /**
     * @dev Error thrown when attempting to unlock tokens before the lock period has expired.
     * @param currentPeriod The current time or period.
     * @param lockReleasePeriod The required time or period that must be reached to unlock the tokens.
     */
    error LockDurationNotExpired(uint256 currentPeriod, uint256 lockReleasePeriod);
    error InsufficientLockedBalance(uint256 available, uint256 required);

    /**
     * @dev Locks a specified amount of tokens for a particular account until a given release period.
     * @param account The address of the account whose tokens are to be locked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be locked.
     */
    function lock(address account, uint256 lockReleasePeriod, uint256 value) external;

    /**
     * @dev Unlocks a specified amount of tokens for a particular account for a given release period.
     * @param account The address of the account whose tokens are to be unlocked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be unlocked.
     */
    function unlock(address account, uint256 lockReleasePeriod, uint256 value) external;

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
    function previewUnlock(address account, uint256 lockReleasePeriod)
        external
        view
        returns (uint256 amountUnlockable);

    /**
     * @dev Rolls over a specified amount of unlocked tokens for another lock period.
     * @param account The address of the account whose tokens are to be rolled over.
     * @param lockReleasePeriod The new period during which these tokens will be locked.
     * @param value The amount of tokens to be rolled over and locked for the new period.
     */
    function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) external;
}
