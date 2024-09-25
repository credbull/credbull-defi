// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITimelockOpenEnded
 * @dev Interface for managing open-ended token locks with multiple deposit periods.
 * Tokens are locked indefinitely, but associated with specific deposit periods for tracking.
 */
interface ITimelockOpenEnded {
    error ITimelockOpenEnded__ExceededMaxUnlock(address account, uint256 amount, uint256 maxUnlock);

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    /// MUST always be the total amount locked, even if some locks are unlocked
    function lockedAmount(address account, uint256 depositPeriod) external view returns (uint256 lockedAmount_);

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function unlockedAmount(address account, uint256 depositPeriod) external view returns (uint256 unlockedAmount_);
}
