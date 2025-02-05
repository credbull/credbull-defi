// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITimelock
 * @dev Interface for managing token locks with specific release periods.
 * Tokens are locked until a given release period, after which they can be unlocked.
 */
interface ITimelock {
    error ITimelock__LockDurationNotExpired(address account, uint256 currentPeriod, uint256 lockReleasePeriod);
    error ITimelock__ExceededMaxUnlock(
        address account, uint256 lockReleasePeriod, uint256 unlockAmount, uint256 maxUnlockAmount
    );

    /// @notice Locks `amount` of tokens for `account` until `lockReleasePeriod`.
    function lock(address account, uint256 lockReleasePeriod, uint256 amount) external;

    /// @notice Unlocks `amount` of tokens for `account` at `lockReleasePeriod`.
    function unlock(address account, uint256 lockReleasePeriod, uint256 amount) external;

    /// @notice Rolls over unlocked `amount` of tokens for `account` to a new lock period.
    function rolloverUnlocked(address account, uint256 origLockReleasePeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at `lockReleasePeriod`.
    function lockedAmount(address account, uint256 lockReleasePeriod) external view returns (uint256 lockedAmount_);

    /// @notice Returns the max amount of tokens unlockable for `account` at `lockReleasePeriod`.
    function maxUnlock(address account, uint256 lockReleasePeriod) external view returns (uint256 unlockableAmount_);

    /// @notice Returns the periods with locked tokens for `account` between `fromPeriod` and `toPeriod`.
    function lockPeriods(address account, uint256 fromPeriod, uint256 toPeriod, uint256 increment)
        external
        view
        returns (uint256[] memory lockedPeriods_, uint256[] memory lockedAmounts_);
}
