// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC6372 } from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import { Time } from "@openzeppelin/contracts/utils/types/Time.sol";

/**
 * @title Timer
 * Utility to provide current time and elapsed time periods
 *
 * @dev Please note when used on "period-aware" contracts/libs, e.g. `CalcInterest`, `MultiTokenVault`:
 * - `Daily` periods - use elapsed24Hours().  However, a day is not always 24 hours due to leap seconds.
 * - `Seconds` periods - use elapsedSeconds().  Fine for CalcInterest, not for MultiTokenVault depositPeriods.  Too many periods to iterate!
 * - `Monthly` or `Annual` - not supported due to the (more) complex rules
 */
contract Timer is IERC6372 {
    uint48 public startTime;

    error Timer__ERC6372InconsistentClock(uint48 actualClock, uint48 expectedClock);

    constructor(uint48 startTime_) {
        startTime = startTime_;
    }

    /// @dev returns the current timepoint (timestamp mode)
    function clock() public view virtual returns (uint48) {
        return Time.timestamp();
    }

    /// @dev returns the clock mode as required by EIP-6372.  For timestamp, MUST return mode=timestamp.
    function CLOCK_MODE() public view virtual returns (string memory) {
        uint48 actualClock = clock();
        uint48 expectedClock = Time.timestamp();

        if (actualClock != expectedClock) {
            revert Timer__ERC6372InconsistentClock(actualClock, expectedClock);
        }
        return "mode=timestamp";
    }

    /// @dev returns the elapsed time in seconds since starTime
    function elapsedSeconds() public view returns (uint48) {
        return clock() - startTime;
    }

    /// @dev returns the elapsed time in minutes since starTime
    function elapsedMinutes() public view returns (uint48) {
        return elapsedSeconds() / 1 minutes;
    }

    /// @dev returns the elapsed 24-hour periods since starTime
    function elapsed24Hours() public view returns (uint48) {
        return elapsedSeconds() / 24 hours;
    }

    function _setStartTime(uint48 startTime_) internal {
        startTime = startTime_;
    }
}
