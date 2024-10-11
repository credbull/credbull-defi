// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IYieldStrategy
 * @dev Interface for calculating yield and price based on principal and elapsed time periods.
 */
interface IYieldStrategy {
    /// @notice When the `contextContract` parameter is invalid.
    error IYieldStrategy_InvalidContextAddress();

    /**
     * @notice When the `fromPeriod` and `toPeriod` parameters do not form a valid range, as governed by the
     *  [RangeInclusion].
     * @param fromPeriod The 'from' period of the period range.
     * @param toPeriod The 'to' period of the period range.
     * @param rangeInclusion The effective [RangeInclusion].
     */
    error IYieldStrategy_InvalidPeriodRange(uint256 fromPeriod, uint256 toPeriod, RangeInclusion rangeInclusion);

    /// @notice Encapsulates how both Periods of a Period Range are included, or not, when Calculating Yield.
    enum RangeInclusion {
        // @dev The From Period is inclusive.
        From,
        // @dev The To Period is inclusive.
        To,
        // @dev Both the From and the To Periods are inclusive.
        Both,
        // @dev Neither of the From or the To Periods are inclusive.
        Neither
    }

    /// @return rangeInclusion_ The [RangeInclusion] property of this [IYieldStrategy] realisation.
    function rangeInclusion() external view returns (RangeInclusion rangeInclusion_);

    /**
     * @notice Calculates the effective `noOfPeriods`, `actualFromPeriod` and `actualToPeriod` for the specified
     *  parameters and according to the effective [RangeInclusion].
     * @dev Uses the `inclusion` property to determine the effective period range for the specified 'from' and 'to'
     *  periods.
     *  Reverts with [IYieldStrategy_InvalidPeriodRange] if the `fromPeriod` and `toPeriod` do not form a valid
     *  Period Range, as governed by the effective [RangeInclusion].
     *  This is NOT a temporal calculation and the responsibility of applying these results temporally is with the
     *  invoking client.
     *
     * @param fromPeriod The start of the Period Range.
     * @param toPeriod The end of the Period Range.
     * @return noOfPeriods The number of periods between `fromPeriod` and `toPeriod` as governed by the [RangeInclusion].
     * @return actualFromPeriod The effective 'from' period for the range, as governed by the [RangeInclusion].
     * @return actualToPeriod The effective 'to' period for the range, as governed by the [RangeInclusion].
     */
    function periodRangeFor(uint256 fromPeriod, uint256 toPeriod)
        external
        view
        returns (uint256 noOfPeriods, uint256 actualFromPeriod, uint256 actualToPeriod);

    /**
     * @notice Returns the yield for `principal` over the time period from `fromPeriod` to `toPeriod`.
     * @dev Reverts with [IYieldStrategy_InvalidContextAddress] if `contextContract` is invalid.
     *  Reverts with [IYieldStrategy_InvalidPeriodRange] if the `fromPeriod` and `toPeriod` do not form a valid
     * Period Range.
     *
     * @param contextContract The [address] of the contract providing additional data required for the calculation.
     * @param principal The principal amount to calculate the yield for.
     * @param fromPeriod The start of the Period Range.
     * @param toPeriod The end of the Period Range.
     * @return yield The calculated yield.
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        external
        view
        returns (uint256 yield);

    /**
     * @notice Returns the price after `periodsElapsed`.
     * @dev Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.
     *
     * @param contextContract The [address] of the contract providing additional data required for the calculation.
     * @param periodsElapsed The number of Time Periods that have elapsed at the current time.
     * @return price The calculated Price.
     */
    function calcPrice(address contextContract, uint256 periodsElapsed) external view returns (uint256 price);
}
