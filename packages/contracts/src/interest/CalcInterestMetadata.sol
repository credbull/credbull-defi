// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CalcInterestMetadata
 * @dev Implements interest calculation parameters like rate, frequency, and scale.
 */
abstract contract CalcInterestMetadata is ICalcInterestMetadata {
    uint256 public immutable RATE_PERCENT_SCALED; // rate in percentage * scale.  e.g., at scale 1e3, 5% = 5000.
    uint256 public immutable FREQUENCY;
    uint256 public immutable SCALE;

    constructor(uint256 ratePercentageScaled_, uint256 frequency_, uint256 decimals_) {
        RATE_PERCENT_SCALED = ratePercentageScaled_;
        FREQUENCY = frequency_;
        SCALE = 10 ** decimals_;
    }

    /// @notice Returns the frequency of interest application.
    function frequency() public view virtual returns (uint256 frequency_) {
        return FREQUENCY;
    }

    /// @notice Returns the annual interest rate as a percentage, scaled.
    function rateScaled() public view virtual returns (uint256 ratePercentageScaled_) {
        return RATE_PERCENT_SCALED;
    }

    /// @notice Returns the scale factor for calculations (e.g., 10^18 for 18 decimals).
    function scale() public view virtual returns (uint256 scale_) {
        return SCALE;
    }

    /// @notice Returns a string representation of the interest calculation metadata.
    function toString() public view returns (string memory) {
        return string.concat(
            " CalcInterest [ rate: ",
            Strings.toString(RATE_PERCENT_SCALED),
            " frequency: ",
            Strings.toString(FREQUENCY),
            " scale: ",
            Strings.toString(SCALE),
            " ] "
        );
    }
}
