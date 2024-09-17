// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CalcInterestParams
 * @dev This contract contains the state to implement ICalcInterestMetadata
 */
abstract contract CalcInterestMetadata is ICalcInterestMetadata {
    uint256 public immutable INTEREST_RATE; // IR as %, e.g. 15 for 15% (or 0.15)
    uint256 public immutable FREQUENCY;

    uint256 public immutable SCALE;

    constructor(uint256 interestRatePercentage, uint256 frequency, uint256 decimals) {
        INTEREST_RATE = interestRatePercentage;
        FREQUENCY = frequency;
        SCALE = 10 ** decimals;
    }

    /**
     * @notice Returns the frequency of interest application (number of periods in a year).
     * @return frequency The frequency value.
     */
    function getFrequency() public view virtual returns (uint256 frequency) {
        return FREQUENCY;
    }

    /**
     * @notice Returns the annual interest rate as a percentage.
     * @return interestRateInPercentage The interest rate as a percentage.
     */
    function getInterestInPercentage() public view virtual returns (uint256 interestRateInPercentage) {
        return INTEREST_RATE;
    }

    /**
     * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
     * @return scale The scale factor.
     */
    function getScale() public view virtual returns (uint256 scale) {
        return SCALE;
    }

    function toString() public view returns (string memory) {
        return string.concat(
            " CalcInterest [ ",
            " IR = ",
            Strings.toString(INTEREST_RATE),
            " Frequency = ",
            Strings.toString(FREQUENCY),
            " Scale = ",
            Strings.toString(SCALE),
            " ] "
        );
    }
}
