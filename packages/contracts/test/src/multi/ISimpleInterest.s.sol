// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Simple Interest Interface
 * @dev This interface provides functions to calculate interest and principal amounts over time.
 *
 * @notice The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
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
 */
interface ISimpleInterest {
    // ============= scaled ================

    function calcInterestWithScale(uint256 principal, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 interest);

    function calcDiscountedWithScale(uint256 principal, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 discounted);

    function calcPrincipalFromDiscountedWithScale(uint256 discounted, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 principal);

    function getScale() external view returns (uint256 scale);

    // ============= unscaled ================
    // TODO - should these be deprecated ??

    function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 interest);

    function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 discounted);

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 principal);

    function getFrequency() external view returns (uint256 frequency);

    function getInterestInPercentage() external view returns (uint256 interestRateInPercentage);
}
