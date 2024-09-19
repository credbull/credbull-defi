// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

/**
 * @title ITimelockOpenEnded
 * @dev Interface for managing open-ended token locks with multiple deposit periods.
 * Tokens are locked indefinitely, but associated with specific deposit periods for tracking.
 */
contract TimelockOpenEnded is ITimelockOpenEnded {
    IERC5679Ext1155 public immutable DEPOSITS;
    IERC5679Ext1155 public immutable UNLOCKED_DEPOSITS;

    /// @dev Error for insufficient locked balance for `account`.
    error TimelockOpenEnded__InsufficientLockedBalance(address account, uint256 available, uint256 required);

    constructor(IERC5679Ext1155 deposits, IERC5679Ext1155 unlockedDeposits) {
        DEPOSITS = deposits;
        UNLOCKED_DEPOSITS = unlockedDeposits;
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public {
        uint256 maxUnlockableAmount = _maxUnlockableAmount(account, depositPeriod);
        if (amount > maxUnlockableAmount) {
            revert TimelockOpenEnded__InsufficientLockedBalance(account, maxUnlockableAmount, amount);
        }

        UNLOCKED_DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function _maxUnlockableAmount(address account, uint256 depositPeriod)
        public
        view
        returns (uint256 maxUnlockableAmount)
    {
        return lockedAmount(account, depositPeriod) - unlockedAmount(account, depositPeriod);
    }

    /// @notice Returns the amount of tokens unlocked for `account` from the given `depositPeriod`.
    function unlockedAmount(address account, uint256 depositPeriod) public view returns (uint256 unlockedAmount_) {
        // address account, uint256 depositPeriod) external view returns (uint256 unlockedAmount_) {
        return UNLOCKED_DEPOSITS.balanceOf(account, depositPeriod);
    }

    /// @notice Returns the deposit periods with non-zero unlocked tokens for `account`.
    function unlockedPeriods(address /* account */ ) external pure returns (uint256[] memory depositPeriods) {
        return new uint256[](0); // TODO - to implement
    }

    // ======================== helpers - but not required ========================

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    // TODO - we don't need a lock here.  all entries in the DEPOSITS are locked unless unlocked.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function lockedAmount(address account, uint256 depositPeriod) public view returns (uint256 lockedAmount_) {
        return DEPOSITS.balanceOf(account, depositPeriod);
    }
}
