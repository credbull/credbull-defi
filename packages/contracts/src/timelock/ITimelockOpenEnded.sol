// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITimelockOpenEnded
 * @dev Interface for managing open-ended token locks with multiple deposit periods.
 * Tokens are locked indefinitely, but associated with specific deposit periods for tracking.
 */
interface ITimelockOpenEnded {
    error ITimelockOpenEnded__LockedBalanceInsufficient(address account, uint256 available, uint256 required);
    error ITimelockOpenEnded__UnlockedBalanceInsufficient(address account, uint256 available, uint256 required);
    error ITimelockOpenEnded__RequestedUnlockedBalanceInsufficient(address account, uint256 available, uint256 required);
    error ITimelockOpenEnded__NoticePeriodInsufficient(address account, uint256 requestedPeriod, uint256 requiredPeriod);
    error ITimelockOpenEnded__RedeemPeriodNotReached(address account, uint256 currentPeriod, uint256 redeemPeriod); // TODO - better name

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    /// MUST always be the total amount locked, even if some locks are unlocked
    function lockedAmount(address account, uint256 depositPeriod) external view returns (uint256 lockedAmount_);

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) external;

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function unlockedAmount(address account, uint256 depositPeriod) external view returns (uint256 unlockedAmount_);

    /// @notice Maximum amount of tokens that can be unlocked for `account` at the`depositPeriod`.
    /// MUST return lockedAmount if no unlocks
    /// MUST return reduced amount if unlocks, e.g. maxLockedAmount = lockedAmount - unlockedAmount
    function maxUnlockAmount(address account, uint256 depositPeriod) external view returns (uint256 maxUnlockAmount_);

    /// @notice Returns the periods with unlocked tokens for `account` between `fromPeriod` and `toPeriod`.
    function unlockedPeriods(address account, uint256 fromPeriod, uint256 toPeriod)
        external
        view
        returns (uint256[] memory unlockedPeriods_);
}
