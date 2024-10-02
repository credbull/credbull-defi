// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC6372 } from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

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
    uint256 public startTimestamp;

    error Timer__ERC6372InconsistentTime(uint256 actualTime, uint256 expectTIme);
    error Timer__StartTimeNotReached(uint256 currentTime, uint256 startTime);

    constructor(uint256 startTimestamp_) {
        startTimestamp = startTimestamp_;
    }

    /// @dev returns the current timepoint (timestamp mode)
    function timestamp() public view virtual returns (uint256 timestamp_) {
        return block.timestamp;
    }

    /// @dev returns the current timepoint (timestamp mode) in uint256
    function clock() public view virtual returns (uint48 clock_) {
        return SafeCast.toUint48(timestamp());
    }

    /// @dev returns the clock mode as required by EIP-6372.  For timestamp, MUST return mode=timestamp.
    function CLOCK_MODE() public view virtual returns (string memory) {
        if (timestamp() != block.timestamp) {
            revert Timer__ERC6372InconsistentTime(timestamp(), block.timestamp);
        }
        return "mode=timestamp";
    }

    /// @dev returns the elapsed time in seconds since starTime
    function elapsedSeconds() public view returns (uint256 elapsedSeconds_) {
        if (startTimestamp > timestamp()) {
            revert Timer__StartTimeNotReached(timestamp(), startTimestamp);
        }

        return timestamp() - startTimestamp;
    }

    /// @dev returns the elapsed time in minutes since starTime
    function elapsedMinutes() public view returns (uint256 elapsedMinutes_) {
        return elapsedSeconds() / 1 minutes;
    }

    /// @dev returns the elapsed 24-hour periods since starTime
    function elapsed24Hours() public view returns (uint256 elapsed24hours_) {
        return elapsedSeconds() / 24 hours;
    }

    function _setStartTimestamp(uint256 startTimestamp_) internal {
        startTimestamp = startTimestamp_;
    }
}
