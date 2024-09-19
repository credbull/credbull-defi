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

    constructor(IERC5679Ext1155 depositLedger) {
        DEPOSITS = depositLedger;
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 /* amount */ ) external view {
        DEPOSITS.balanceOf(account, depositPeriod); // TODO - to implement
    }

    /// @notice Returns the amount of tokens unlocked for `account` from the given `depositPeriod`.
    function unlockedAmount(address, uint256) external pure returns (uint256) {
        // address account, uint256 depositPeriod) external view returns (uint256 unlockedAmount_) {
        return 0; // TODO - to implement
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
    function lockedAmount(address account, uint256 depositPeriod) public view returns (uint256 amountLocked) {
        return DEPOSITS.balanceOf(account, depositPeriod);
    }
}
