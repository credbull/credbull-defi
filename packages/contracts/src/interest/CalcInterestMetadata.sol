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

    constructor(uint256 _ratePercentageScaled, uint256 _frequency, uint256 _decimals) {
        RATE_PERCENT_SCALED = _ratePercentageScaled;
        FREQUENCY = _frequency;
        SCALE = 10 ** _decimals;
    }

    /**
     * @notice Returns the frequency of interest application (number of periods in a year).
     * @return _frequency The frequency value.
     */
    function frequency() public view virtual returns (uint256 _frequency) {
        return FREQUENCY;
    }

    /**
     * @notice Returns the annual interest rate as a percentage.
     * @return _ratePercentageScaled The interest rate as a percentage * scale
     */
    function rateScaled() public view virtual returns (uint256 _ratePercentageScaled) {
        return RATE_PERCENT_SCALED;
    }

    /**
     * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
     * @return _scale The scale factor.
     */
    function scale() public view virtual returns (uint256 _scale) {
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
