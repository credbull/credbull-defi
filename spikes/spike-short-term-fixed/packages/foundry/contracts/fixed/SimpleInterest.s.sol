// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ISimpleInterest } from "@credbull/contracts/interfaces/ISimpleInterest.s.sol";

/**
 * https://en.wikipedia.org/wiki/Interest
 *
 * Simple interest is calculated only on the principal amount, or on that portion of the principal amount that remains.
 * It excludes the effect of compounding. Simple interest can be applied over a time period other than a year, for example, every month.
 *
 * Simple interest is calculated according to the following formula: (IR * P * m) / f
 * - IR is the simple annual interest rate
 * - P is the Principal (aka initial amount)
 * - m is the number of time periods elapsed
 * - f is the frequency of applying interest (how many interest periods in a year)
 *
 *
 *  @notice The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
 * This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.
 *
 * For example:
 * ```
 * uint256 originalPrincipal = 1000;
 * uint256 discountedValue = calcDiscounted(originalPrincipal);
 * uint256 recoveredPrincipal = calcPrincipalFromDiscounted(discountedValue);
 * assert(recoveredPrincipal == originalPrincipal);
 * ```
 *
 * This property ensures that no information is lost when discounting and then recovering the principal,
 * making the system consistent and predictable.
 *
 */
contract SimpleInterest is ISimpleInterest {
    using Math for uint256;

    uint256 public immutable INTEREST_RATE_PERCENTAGE;
    uint256 public immutable FREQUENCY;

    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public immutable PAR = 1;

    Math.Rounding public constant ROUNDING = Math.Rounding.Floor;

    error PrincipalLessThanScale(uint256 principal, uint256 scale);

    constructor(uint256 interestRatePercentage, uint256 frequency) {
        INTEREST_RATE_PERCENTAGE = interestRatePercentage;
        FREQUENCY = frequency;
    }

    function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed)
        public
        view
        virtual
        returns (uint256 interest)
    {
        if (principal < SCALE) {
            revert PrincipalLessThanScale(principal, SCALE);
        }

        uint256 interestScaled =
            principal.mulDiv(INTEREST_RATE_PERCENTAGE * numTimePeriodsElapsed * SCALE, FREQUENCY * 100, ROUNDING);

        return unscale(interestScaled);
    }

    function _calcInterestWithScale(uint256 principal, uint256 numTimePeriodsElapsed)
        internal
        view
        returns (uint256 _interestScaled)
    {
        uint256 interestScaled =
            principal.mulDiv(INTEREST_RATE_PERCENTAGE * numTimePeriodsElapsed * SCALE, FREQUENCY * 100, ROUNDING);

        return interestScaled;
    }

    function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256) {
        if (principal < SCALE) {
            revert PrincipalLessThanScale(principal, SCALE);
        }

        uint256 discountedScaled = principal * SCALE - _calcInterestWithScale(principal, numTimePeriodsElapsed);

        return unscale(discountedScaled);
    }

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 interestFactor =
            INTEREST_RATE_PERCENTAGE.mulDiv(numTimePeriodsElapsed * SCALE, FREQUENCY * 100, ROUNDING);

        uint256 scaledPrincipal = discounted.mulDiv(SCALE * SCALE, SCALE - interestFactor, ROUNDING);

        return unscale(scaledPrincipal);
    }

    function unscale(uint256 amount) internal pure returns (uint256) {
        return amount / SCALE;
    }

    function getFrequency() public view virtual returns (uint256 frequency) {
        return FREQUENCY;
    }

    function getInterestInPercentage() public view virtual returns (uint256 interestRateInPercentage) {
        return INTEREST_RATE_PERCENTAGE;
    }
}
