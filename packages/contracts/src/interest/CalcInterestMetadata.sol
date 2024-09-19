// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CalcInterestParams
 * @dev Sate to implement ICalcInterestMetadata
 */
abstract contract CalcInterestMetadata is ICalcInterestMetadata {
    uint256 public immutable RATE_PERCENT_SCALED; // IR as % * SCALE, e.g. "15_000" for 15% * scale[1e3]
    uint256 public immutable FREQUENCY;

    uint256 public immutable SCALE;

    constructor(uint256 ratePercentageScaled_, uint256 frequency_, uint256 decimals_) {
        RATE_PERCENT_SCALED = ratePercentageScaled_;
        FREQUENCY = frequency_;
        SCALE = 10 ** decimals_;
    }

    /**
     * @notice Returns the frequency of interest application (number of periods in a year).
     * @return frequency_ The frequency value.
     */
    function frequency() public view virtual returns (uint256 frequency_) {
        return FREQUENCY;
    }

    /**
     * @notice Returns the annual interest rate as a percentage.
     * @return ratePercentageScaled_ The interest rate as a percentage * scale
     */
    function rateScaled() public view virtual returns (uint256 ratePercentageScaled_) {
        return RATE_PERCENT_SCALED;
    }

    /**
     * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
     * @return scale_ The scale factor.
     */
    function scale() public view virtual returns (uint256 scale_) {
        return SCALE;
    }

    function toString() public view returns (string memory) {
        return string.concat(
            " CalcInterest [ ",
            " rate: ",
            Strings.toString(RATE_PERCENT_SCALED),
            " frequency: ",
            Strings.toString(FREQUENCY),
            " scale: ",
            Strings.toString(SCALE),
            " ] "
        );
    }
}
