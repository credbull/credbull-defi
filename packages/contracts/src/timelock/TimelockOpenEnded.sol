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

    // ======================== lock ========================

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function lockedAmount(address account, uint256 depositPeriod) public view returns (uint256 lockedAmount_) {
        return DEPOSITS.balanceOf(account, depositPeriod);
    }

    // ======================== unlock ========================

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public {
        uint256 maxUnlockableAmount_ = maxUnlockAmount(account, depositPeriod);
        if (amount > maxUnlockableAmount_) {
            revert TimelockOpenEnded__InsufficientLockedBalance(account, maxUnlockableAmount_, amount);
        }

        UNLOCKED_DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function maxUnlockAmount(address account, uint256 depositPeriod) public view returns (uint256 maxUnlockAmount_) {
        return lockedAmount(account, depositPeriod) - unlockedAmount(account, depositPeriod);
    }

    /// @notice Returns the amount of tokens unlocked for `account` from the given `depositPeriod`.
    function unlockedAmount(address account, uint256 depositPeriod) public view returns (uint256 unlockedAmount_) {
        return UNLOCKED_DEPOSITS.balanceOf(account, depositPeriod);
    }

    /// @notice Returns the periods with unlocked tokens for `account` between `fromPeriod` and `toPeriod`.
    function unlockedPeriods(address account, uint256 fromPeriod, uint256 toPeriod)
        external
        view
        returns (uint256[] memory unlockedPeriods_)
    {
        uint256 numPeriodsFromToInclusive = toPeriod - fromPeriod + 1;
        uint256[] memory tempUnlockPeriods = new uint256[](numPeriodsFromToInclusive);

        uint256 accountUnlockPeriodCount = 0;
        for (uint256 i = fromPeriod; i <= toPeriod; i++) {
            if (unlockedAmount(account, i) > 0) {
                tempUnlockPeriods[accountUnlockPeriodCount] = i;
                accountUnlockPeriodCount++;
            }
        }

        uint256[] memory resUnlockedPeriods = new uint256[](accountUnlockPeriodCount);
        for (uint256 i = 0; i < accountUnlockPeriodCount; i++) {
            resUnlockedPeriods[i] = tempUnlockPeriods[i];
        }

        return resUnlockedPeriods;
    }
}
