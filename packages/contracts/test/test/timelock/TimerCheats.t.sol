// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Timer } from "@credbull/timelock/Timer.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TimerCheats is Initializable, Timer {
    uint256 public cheatTimestamp;

    function __TimerCheats__init(uint256 startTime_) public initializer {
        __Timer_init(startTime_);
        cheatTimestamp = startTime_;
    }

    /// @dev returns the current timestamp
    function timestamp() public view virtual override returns (uint256 timestamp_) {
        return cheatTimestamp;
    }

    /// @dev sets the internal timestamp to a specific value
    function warp(uint256 newTimestamp) public {
        cheatTimestamp = newTimestamp;
    }

    function warp24HourPeriods(uint256 numPeriods) public {
        // use startTime as our "epoch" - warp 24 hour periods from that
        cheatTimestamp = (startTimestamp + numPeriods * 24 hours);
    }

    function setStartTime(uint256 startTime_) public {
        _setStartTimestamp(startTime_);
    }
}
