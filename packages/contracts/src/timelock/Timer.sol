// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC6372 } from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import { Time } from "@openzeppelin/contracts/utils/types/Time.sol";

contract Timer is IERC6372 {
    uint48 public START_TiME;

    error ERC6372InconsistentClock();

    /// @dev the clock was incorrectly modified.

    /// @dev sets the start time
    constructor(uint48 startTime_) {
        START_TiME = startTime_;
    }

    /// @dev returns the current timepoint (timestamp mode)
    function clock() public view virtual returns (uint48) {
        return Time.timestamp();
    }

    /// @dev returns the clock mode as required by EIP-6372.  For timestamp, MUST return mode=timestamp.
    function CLOCK_MODE() public view virtual returns (string memory) {
        if (clock() != Time.timestamp()) {
            revert ERC6372InconsistentClock();
        }
        return "mode=timestamp";
    }

    /// @dev returns the elapsed time in seconds since START_TiME
    function elapsedSeconds() public view returns (uint48) {
        return clock() - START_TiME;
    }

    /// @dev returns the elapsed time in minutes since START_TiME
    function elapsedMinutes() public view returns (uint48) {
        return elapsedSeconds() / 1 minutes;
    }

    /// @dev returns the elapsed 24-hour periods since START_TiME
    function elapsed24Hours() public view returns (uint48) {
        return elapsedSeconds() / 24 hours;
    }
}
