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

    constructor(uint256 _interestRatePercentage, uint256 _frequency, uint256 _decimals) {
        INTEREST_RATE = _interestRatePercentage;
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
     * @return _interestRatePercentage The interest rate as a percentage.
     */
    function interestRate() public view virtual returns (uint256 _interestRatePercentage) {
        return INTEREST_RATE;
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
