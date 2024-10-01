// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";
import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";

/**
 * @title Our triple rate context reference implementation, realising [ITripleRateContext].
 * @dev This is an abstract contract intended to be inherited from and overriden with Access Control functionality.
 */
abstract contract TripleRateContext is CalcInterestMetadata, ITripleRateContext {
    /**
     * @notice Reverts when the Tenor Period is before the currently set Tenor Period.
     *
     * @param tenorPeriod The current Tenor Period.
     * @param newTenorPeriod The attempted update Tenor Period.
     */
    error TripleRateContext_TenorPeriodRegressionNotAllowed(uint256 tenorPeriod, uint256 newTenorPeriod);

    /**
     * @notice Emits when the current [TenorPeriodRate] is set.
     *
     * @param reducedRate The updated Reduced Rate for the Tenor Period.
     * @param tenorPeriod The updated current Tenor Period.
     */
    event CurrentTenorPeriodRateChanged(uint256 reducedRate, uint256 tenorPeriod);

    /// @notice The Tenor, or Maturity Period, of this context.
    uint256 public immutable TENOR;

    TenorPeriodRate internal _current;
    TenorPeriodRate internal _previous;

    /**
     * @notice Creates a [TripleRateContext] instance.
     *
     * @param fullRateInPercentageScaled_ The [uint256] 'full' rate, in scaled percentage form.
     * @param reducedRateInPercentageScaled_ The [uint256] 'reduced' rate, in scaled percentage form.
     * @param fromPeriod_ The [uint256] Period to apply the reduced rate to.
     * @param frequency_ The [uint256] interest frequency.
     * @param tenor_ The [uint256] product maturity period, or tenor.
     * @param decimals The [uint256] number of decimals that is the applied scaling.
     */
    constructor(
        uint256 fullRateInPercentageScaled_,
        uint256 reducedRateInPercentageScaled_,
        uint256 fromPeriod_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals
    ) CalcInterestMetadata(fullRateInPercentageScaled_, frequency_, decimals) {
        TENOR = tenor_;

        _setReducedRateAt(fromPeriod_, reducedRateInPercentageScaled_);
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
    function currentTenorPeriodRate() public view override returns (TenorPeriodRate memory currentTenorPeriodRate_) {
        currentTenorPeriodRate_ = _current;
    }

    /**
     * @inheritdoc ITripleRateContext
     */
    function previousTenorPeriodRate() public view override returns (TenorPeriodRate memory previousTenorPeriodRate_) {
        previousTenorPeriodRate_ = _previous;
    }

    /**
     * @notice Mutator function to set the current Tenor Period and its associated Reduced Rate.
     * @dev Reverts with [TripleRateContext_TenorPeriodRegressionNotAllowed] if `tenorPeriod_` is before the
     *  current Tenor Period.
     * Emits [CurrentTenorPeriodRateChanged] upon mutation.
     * Expected to be Access Controlled.
     *
     * @param tenorPeriod_ The [uint256] Tenor Period at which to set the associated Rate.
     * @param reducedRateScaled_ The [uint256] Reduced Rate scaled percentage value.
     */
    function setReducedRateAt(uint256 tenorPeriod_, uint256 reducedRateScaled_) public virtual {
        if (tenorPeriod_ <= _current.effectiveFromTenorPeriod) {
            revert TripleRateContext_TenorPeriodRegressionNotAllowed(_current.effectiveFromTenorPeriod, tenorPeriod_);
        }

        _setReducedRateAt(tenorPeriod_, reducedRateScaled_);
    }

    /**
     * @dev A private convenience function for setting the Reduced Interest and its associated Rate Tenor Period,
     *  without Tenor Period regression checks.
     * Emits [CurrentTenorPeriodRateChanged] upon mutation.
     *
     * @param tenorPeriod_ The [uint256] Tenor Period at which to set the associated Rate.
     * @param reducedRateScaled_ The [uint256] Reduced Rate scaled percentage value.
     */
    function _setReducedRateAt(uint256 tenorPeriod_, uint256 reducedRateScaled_) private {
        _previous = _current;
        _current = TenorPeriodRate({ interestRate: reducedRateScaled_, effectiveFromTenorPeriod: tenorPeriod_ });

        emit CurrentTenorPeriodRateChanged(reducedRateScaled_, tenorPeriod_);
    }
}
