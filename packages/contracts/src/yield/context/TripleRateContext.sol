// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";
import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Our triple rate context reference implementation, realising [ITripleRateContext].
 * @dev This is an abstract contract intended to be inherited from and overriden with Access Control functionality.
 */
abstract contract TripleRateContext is Initializable, CalcInterestMetadata, ITripleRateContext {
    /// @notice Constructor parameters encapsulated in a struct.
    struct ContextParams {
        /// @notice The 'full' interest rate, in scaled percentage form.
        uint256 fullRateScaled;
        /// @notice A [PeriodRate] encapsulating the initial 'reduced' interest rate and its effective period.
        PeriodRate initialReducedRate;
        /// @notice The interest frequency.
        uint256 frequency; // MUST be a daily frequency, either 360 or 365
        /// @notice The product maturity period, or tenor.
        uint256 tenor;
        /// @notice The number of decimals that is the applied scaling.
        uint256 decimals;
    }

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

    /**
     * @notice Reverts when the Period is before the currently set Period.
     *
     * @param currentPeriod The current Period.
     * @param updatePeriod The attempted update Period.
     */
    error TripleRateContext_PeriodRegressionNotAllowed(uint256 currentPeriod, uint256 updatePeriod);

    /// @notice The Tenor, or Maturity Period, of this context.
    uint256 public TENOR;

    /**
     * @notice The [PeriodRate] that is currently in effect.
     * @dev When this is set, the existing value is pushed to the `_previous` [PeriodRate], thus maintaining a 2 Tenor
     *  Period 'history', for calculating yield correctly.
     *  This is only mutated by internal functions and is access controlled to the Operator user.
     */
    PeriodRate internal _current;
    /**
     * @notice The [PeriodRate] that was previously in effect.
     * @dev This is only mutated by internal functions and is access controlled to the Operator user.
     */
    PeriodRate internal _previous;

    /**
     * @notice Emits when the current [TenorPeriodRate] is set.
     *
     * @param interestRate The updated reduced Interest Rate.
     * @param effectiveFromPeriod The updated period.
     */
    event CurrentPeriodRateChanged(uint256 interestRate, uint256 effectiveFromPeriod);

    constructor() {
        _disableInitializers();
    }

    function __TripleRateContext_init(ContextParams memory params) internal onlyInitializing {
        __CalcInterestMetadata_init(params.fullRateScaled, params.frequency, params.decimals);
        TENOR = params.tenor;
        _setReducedRate(params.initialReducedRate);
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
    function currentPeriodRate() public view override returns (PeriodRate memory currentPeriodRate_) {
        currentPeriodRate_ = _current;
    }

    /**
     * @inheritdoc ITripleRateContext
     */
    function previousPeriodRate() public view override returns (PeriodRate memory previousPeriodRate_) {
        previousPeriodRate_ = _previous;
    }

    /**
     * @notice Sets the 'reduced' Interest Rate to be effective from the `effectiveFromPeriod_` Period.
     * @dev Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if `effectiveFromPeriod_` is before the
     *  current Period.
     * Emits [CurrentPeriodRateChanged] upon mutation. Access is `virtual` to enable Access Control override.
     *
     * @param reducedRateScaled_ The scaled 'reduced' Interest Rate percentage.
     * @param effectiveFromPeriod_ The Period from which the `reducedRateScaled_` is effective.
     */
    function setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_) public virtual {
        if (effectiveFromPeriod_ <= _current.effectiveFromPeriod) {
            revert TripleRateContext_PeriodRegressionNotAllowed(_current.effectiveFromPeriod, effectiveFromPeriod_);
        }

        _setReducedRate(PeriodRate({ interestRate: reducedRateScaled_, effectiveFromPeriod: effectiveFromPeriod_ }));
    }

    /**
     * @dev A private convenience function for setting the  specified 'reduced' Interest Rate [PeriodRate] without
     *  Effective Period regression checks.
     *  Emits [CurrentPeriodRateChanged] upon success.
     *
     * @param candidate_ The [PeriodRate] to set.
     */
    function _setReducedRate(PeriodRate memory candidate_) private {
        _previous = _current;
        _current = candidate_;

        emit CurrentPeriodRateChanged(candidate_.interestRate, candidate_.effectiveFromPeriod);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
