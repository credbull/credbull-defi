// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";
import { ITripleRateContext } from "@credbull/interest/context/ITripleRateContext.sol";

/**
 * @title A triple rate context, with the 'full' rate and 2 reduced rates that apply temporally across 2 tenor periods.
 * @dev Context for yield calculations with a rate and dual reduced rates, applicable across Tenor Periods. All rate
 *  are expressed in percentage terms and scaled using [scale()]. The 'full' rate values are encapsulated by the
 *  [ICalcInterestMetadata].
 */
contract TripleRateContext is CalcInterestMetadata, ITripleRateContext {
    /**
     * @notice Reverts when the Tenor Period is before the currently set Tenor Period.
     *
     * @param tenorPeriod The current Tenor Period.
     * @param newTenorPeriod The attempted update Tenor Period.
     */
    error TripleRateContext_TenorPeriodRegressionNotAllowed(uint256 tenorPeriod, uint256 newTenorPeriod);

    /**
     * @notice Emits when the current Tenor Period is set, with its associated Reduced Rate.
     *
     * @param tenorPeriod The updated current Tenor Period.
     * @param reducedRate The updated Reduced Rate for the Tenor Period.
     */
    event CurrentTenorPeriodAndRateChanged(uint256 tenorPeriod, uint256 reducedRate);

    uint256 public immutable TENOR;

    uint256 internal _currentTenorPeriod;
    uint256 internal _currentReducedRate;

    uint256 internal _previousTenorPeriod;
    uint256 internal _previousReducedRate;

    constructor(
        uint256 fullRateInPercentageScaled_,
        uint256 reducedRateInPercentageScaled_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals
    ) CalcInterestMetadata(fullRateInPercentageScaled_, frequency_, decimals) {
        TENOR = tenor_;

        setReducedRateAt(1, reducedRateInPercentageScaled_);
    }

    /**
     * @inheritdoc ITripleRateContext
     */
    function numPeriodsForFullRate() public view returns (uint256 numPeriods) {
        return TENOR;
    }

    /**
     * @inheritdoc ITripleRateContext
     */
    function currentTenorPeriodAndRate()
        external
        view
        override
        returns (uint256 currentTenorPeriod, uint256 reducedRateInPercentageScaled)
    {
        currentTenorPeriod = _currentTenorPeriod;
        reducedRateInPercentageScaled = _currentReducedRate;
    }

    /**
     * @inheritdoc ITripleRateContext
     */
    function previousTenorPeriodAndRate()
        external
        view
        override
        returns (uint256 previousTenorPeriod, uint256 reducedRateInPercentageScaled)
    {
        previousTenorPeriod = _previousTenorPeriod;
        reducedRateInPercentageScaled = _previousReducedRate;
    }

    /**
     * @notice Mutator function to set the current Tenor Period and its associated Reduced Rate.
     * @dev Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if `tenorPeriod_` is before the
     *  current Tenor Period. Expected to be Access Controlled.
     *  Emits [CurrentTenorPeriodAndRateChanged] upont mutation.
     *
     * @param tenorPeriod_ The [uint256] Tenor Period at which to set the associated Rate.
     * @param reducedRateScaled_ The [uint256] Reduced Rate scaled percentage value.
     */
    function setReducedRateAt(uint256 tenorPeriod_, uint256 reducedRateScaled_) public {
        if (tenorPeriod_ <= _currentTenorPeriod) {
            revert TripleRateContext_TenorPeriodRegressionNotAllowed(_currentTenorPeriod, tenorPeriod_);
        }

        _previousTenorPeriod = _currentTenorPeriod;
        _previousReducedRate = _currentReducedRate;

        _currentTenorPeriod = tenorPeriod_;
        _currentReducedRate = reducedRateScaled_;

        emit CurrentTenorPeriodAndRateChanged(tenorPeriod_, reducedRateScaled_);
    }
}
