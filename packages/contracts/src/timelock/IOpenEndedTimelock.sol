// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IOpenEndedTimelock
 * @dev Interface for managing open-ended token locks with multiple deposit periods.
 * Tokens are locked indefinitely, but associated with specific deposit periods for tracking.
 */
interface IOpenEndedTimelock {
    /// @dev Error for insufficient locked balance for `account`.
    error InsufficientLockedBalance(address account, uint256 available, uint256 required);

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) external;

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function getLockedAmount(address account, uint256 depositPeriod) external view returns (uint256 amountLocked);

    /// @notice Returns the amount of tokens unlockable for `account` from the given `depositPeriod`.
    function previewUnlock(address account, uint256 depositPeriod) external view returns (uint256 amountUnlockable);

    /// @notice Returns the deposit periods with non-zero locked tokens for `account`.
    function getLockPeriods(address account) external view returns (uint256[] memory depositPeriods);
}
