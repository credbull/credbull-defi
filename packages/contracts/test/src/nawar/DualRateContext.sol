// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";
import { IDualRateContext } from "@credbull/interest/IDualRateContext.sol";

/**
 * @title DualRateContext
 * @dev Provides context for dual-rate yield calculation. It includes a full interest rate and a reduced rate
 *      that applies when the holding period is shorter than the full tenor.
 *      This contract extends CalcInterestMetadata to provide interest metadata such as rates and frequency.
 */
contract DualRateContext is CalcInterestMetadata, IDualRateContext {
    /// @notice The reduced interest rate for the first period.
    uint256 public REDUCED_RATE_FIRST_PERIOD;

    /// @notice The reduced interest rate for other periods after the first one.
    uint256 public REDUCED_RATE_OTHER_PERIOD;

    /// @notice The starting period for calculating yield.
    uint256 public FROM_PERIOD;

    /// @notice The ending period for calculating yield.
    uint256 public TO_PERIOD;

    /// @notice The number of periods required to apply the full rate (tenor).
    uint256 public immutable TENOR;

    /**
     * @notice Constructor to initialize the DualRateContext with full and reduced rates, periods, frequency, and tenor.
     * @param _fullRate The full interest rate that applies after the full tenor period.
     * @param _reducedRateFirstPeriod The reduced interest rate for the first partial period before the full tenor is reached.
     * @param _reducedRateOtherPeriod The reduced interest rate for other partial periods.
     * @param _fromPeriod The starting period for calculating the yield.
     * @param _toPeriod The ending period for calculating the yield.
     * @param _frequency The compounding frequency (e.g., annual, monthly) used for interest calculations.
     * @param _tenor The number of periods required to qualify for the full interest rate.
     * @param decimals The decimal precision used for interest rates.
     */
    constructor(
        uint256 _fullRate,
        uint256 _reducedRateFirstPeriod,
        uint256 _reducedRateOtherPeriod,
        uint256 _fromPeriod,
        uint256 _toPeriod,
        uint256 _frequency,
        uint256 _tenor,
        uint256 decimals
    ) CalcInterestMetadata(_fullRate, _frequency, decimals) {
        TENOR = _tenor;
        REDUCED_RATE_FIRST_PERIOD = _reducedRateFirstPeriod;
        REDUCED_RATE_OTHER_PERIOD = _reducedRateOtherPeriod;
        FROM_PERIOD = _fromPeriod;
        TO_PERIOD = _toPeriod;
    }

    /**
     * @notice Returns the full interest rate scaled by the configured decimals.
     * @return rateInPercentage The full interest rate expressed in percentage.
     */
    function fullRateScaled() public view returns (uint256 rateInPercentage) {
        return RATE_PERCENT_SCALED;
    }

    /**
     * @notice Returns the reduced interest rate for partial periods based on whether the period is the first or subsequent.
     * @return rateInPercentage The reduced interest rate, which is either for the first period or subsequent periods.
     */
    function reducedRateScaled() public view returns (uint256 rateInPercentage) {
        if ((TO_PERIOD - FROM_PERIOD) / TENOR >= 1) {
            return REDUCED_RATE_OTHER_PERIOD;
        }
        return REDUCED_RATE_FIRST_PERIOD;
    }

    /**
     * @notice Returns the reduced interest rate for the first period scaled by the configured decimals.
     * @return rateInPercentage The reduced rate for the first period, expressed in percentage.
     */
    function reducedRateFirstPeriodScaled() public view returns (uint256 rateInPercentage) {
        return REDUCED_RATE_FIRST_PERIOD;
    }

    /**
     * @notice Sets a new reduced interest rate for the first period.
     * @param reducedRateInPercentageScaled The new reduced rate for the first period, scaled by the configured decimals.
     */
    function setReducedRateFirstPeriod(uint256 reducedRateInPercentageScaled) public {
        REDUCED_RATE_FIRST_PERIOD = reducedRateInPercentageScaled;
    }

    /**
     * @notice Returns the reduced interest rate for other periods after the first period.
     * @return rateInPercentage The reduced rate for periods after the first, expressed in percentage.
     */
    function reducedRateOtherPeriodScaled() public view returns (uint256 rateInPercentage) {
        return REDUCED_RATE_OTHER_PERIOD;
    }

    /**
     * @notice Sets a new reduced interest rate for periods after the first.
     * @param reducedRateInPercentageScaled The new reduced rate for other periods, scaled by the configured decimals.
     */
    function setReducedRateOtherPeriod(uint256 reducedRateInPercentageScaled) public {
        REDUCED_RATE_OTHER_PERIOD = reducedRateInPercentageScaled;
    }

    /**
     * @notice Sets the starting period for yield calculation.
     * @param _fromPeriod The new starting period.
     */
    function setFromPeriod(uint256 _fromPeriod) public {
        FROM_PERIOD = _fromPeriod;
    }

    /**
     * @notice Sets the ending period for yield calculation.
     * @param _toPeriod The new ending period.
     */
    function setToPeriod(uint256 _toPeriod) public {
        TO_PERIOD = _toPeriod;
    }

    /**
     * @notice Returns the number of periods required to apply the full interest rate.
     * @return numPeriods The number of periods that must pass to qualify for the full interest rate (tenor).
     */
    function numPeriodsForFullRate() public view returns (uint256 numPeriods) {
        return TENOR;
    }
}
