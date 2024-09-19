// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITimelock
 * @dev Interface for managing token locks with specific release periods.
 * Tokens are locked until a given release period, after which they can be unlocked.
 */
interface ITimelock {
    /// @dev Error thrown when trying to unlock tokens before the release period.
    error LockDurationNotExpired(address account, uint256 currentPeriod, uint256 lockReleasePeriod);

    /// @dev Error for insufficient locked balance at a specific release period.
    error InsufficientLockedBalanceAtPeriod(
        address account, uint256 available, uint256 required, uint256 lockReleasePeriod
    );

    /// @notice Locks `amount` of tokens for `account` until `lockReleasePeriod`.
    function lock(address account, uint256 lockReleasePeriod, uint256 amount) external;

    /// @notice Unlocks `amount` of tokens for `account` at `lockReleasePeriod`.
    function unlock(address account, uint256 lockReleasePeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at `lockReleasePeriod`.
    function lockedAmount(address account, uint256 lockReleasePeriod) external view returns (uint256 amountLocked);

    /// @notice Returns the amount of tokens unlockable for `account` at `lockReleasePeriod`.
    function previewUnlock(address account, uint256 lockReleasePeriod)
        external
        view
        returns (uint256 amountUnlockable);

    /// @notice Returns the lock periods where `account` has a non-zero balance.
    function lockPeriods(address account) external view returns (uint256[] memory lockPeriods);
}
