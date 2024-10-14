// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

/**
 * @title YieldStrategy
 * @dev Interface for calculating yield and price based on principal and elapsed time periods.
 */
abstract contract YieldStrategy is IYieldStrategy {
    RangeInclusion internal immutable RANGE_INCLUSION;

    constructor(RangeInclusion rangeInclusion_) {
        RANGE_INCLUSION = rangeInclusion_;
    }

    /**
     * @inheritdoc IYieldStrategy
     */
    function rangeInclusion() public view returns (RangeInclusion rangeInclusion_) {
        return RANGE_INCLUSION;
    }

    /**
     * @inheritdoc IYieldStrategy
     * @dev The heuristic algorithm applied here is:
     *      From > To: Revert [IYieldStrategy_InvalidPeriodRange]
     *
     *      RangeInclusion.To:
     *          IF From == To:
     *              Range: From -> To inclusive
     *              No Of Periods: 1
     *              Actuals: From, To
     *          Range: From + 1 -> To inclusive
     *          No Of Periods: To - From
     *          Actuals: From + 1, To
     *
     *      RangeInclusion.From:
     *          IF From == To:
     *              Range: From -> To inclusive
     *              No Of Periods: 1
     *              Actuals: From, To
     *          Range: From -> To - 1 inclusive
     *          No Of Periods: To - From,
     *          Actuals: From, To - 1
     *
     *      RangeInclusion.Both:
     *          Range: From -> To inclusive
     *          No Of Periods: (To - From) + 1
     *          Actuals: From, To
     *
     *      RangeInclusion.Neither:
     *          IF From == To OR From + 1 == To: Revert [IYieldStrategy_InvalidPeriodRange]
     *          Range: From + 1 -> To - 1 inclusive
     *          No Of Periods: (To - From) - 1
     *          Actuals: From + 1, To - 1
     */
    function periodRangeFor(uint256 fromPeriod, uint256 toPeriod)
        public
        view
        returns (uint256 noOfPeriods, uint256 actualFromPeriod, uint256 actualToPeriod)
    {
        if (fromPeriod > toPeriod) {
            revert IYieldStrategy_InvalidPeriodRange(fromPeriod, toPeriod, RANGE_INCLUSION);
        }
        if (fromPeriod == toPeriod && RANGE_INCLUSION != RangeInclusion.Neither) {
            return (1, fromPeriod, toPeriod);
        }
        if (RANGE_INCLUSION == RangeInclusion.To) {
            return (toPeriod - fromPeriod, fromPeriod + 1, toPeriod);
        } else if (RANGE_INCLUSION == RangeInclusion.From) {
            return (toPeriod - fromPeriod, fromPeriod, toPeriod - 1);
        } else if (RANGE_INCLUSION == RangeInclusion.Both) {
            // Fail if the math is going to overflow.
            if (toPeriod == type(uint256).max && fromPeriod == 0) {
                revert IYieldStrategy_InvalidPeriodRange(fromPeriod, toPeriod, RANGE_INCLUSION);
            }
            return ((toPeriod - fromPeriod) + 1, fromPeriod, toPeriod);
        } else if (RANGE_INCLUSION == RangeInclusion.Neither) {
            if (fromPeriod == toPeriod) {
                revert IYieldStrategy_InvalidPeriodRange(fromPeriod, toPeriod, RANGE_INCLUSION);
            }
            // Cannot overflow here. If 'from' is uint256.max and not greater than 'to', then it is equal to 'to' and
            // will revert in above if.
            if (fromPeriod + 1 == toPeriod) {
                revert IYieldStrategy_InvalidPeriodRange(fromPeriod + 1, toPeriod, RANGE_INCLUSION);
            }
            return ((toPeriod - fromPeriod) - 1, fromPeriod + 1, toPeriod - 1);
        }
    }

    /**
     * @inheritdoc IYieldStrategy
     */
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        external
        view
        virtual
        returns (uint256 yield);

    /**
     * @inheritdoc IYieldStrategy
     */
    function calcPrice(address contextContract, uint256 periodsElapsed) external view virtual returns (uint256 price);
}
