// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";
import { TimerCheats } from "@test/test/timelock/TimerCheats.t.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract SimpleTimelockAsyncUnlock is TimelockAsyncUnlock, TimerCheats {
    IERC5679Ext1155 public immutable DEPOSITS;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits)
        TimelockAsyncUnlock(noticePeriod_)
        TimerCheats(SafeCast.toUint48(block.timestamp))
    {
        DEPOSITS = deposits;
    }

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function lockedAmount(address account, uint256 depositPeriod) public view returns (uint256 lockedAmount_) {
        return DEPOSITS.balanceOf(account, depositPeriod);
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return elapsed24Hours();
    }

    function setCurrentPeriod(uint256 currentPeriod_) public {
        warp24HourPeriods(SafeCast.toUint48(currentPeriod_));
    }

    function _updateLockAfterUnlock(address account, uint256 depositPeriod, uint256 amount) internal virtual override {
        DEPOSITS.burn(account, depositPeriod, amount, _emptyBytesArray());
    }
}