// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Timer } from "@credbull/timelock/Timer.sol";

contract TimerCheats is Timer {
    uint48 public cheatTimestamp;

    constructor(uint48 startTime_) Timer(startTime_) {
        cheatTimestamp = startTime_;
    }

    /// @dev returns the internal cheat timestamp
    function clock() public view override returns (uint48) {
        return cheatTimestamp;
    }

    /// @dev sets the internal timestamp to a specific value
    function warp(uint48 newTimestamp) public {
        cheatTimestamp = newTimestamp;
    }

    function warp24HourPeriods(uint48 numPeriods) public {
        cheatTimestamp += numPeriods * 24 hours;
    }
}
