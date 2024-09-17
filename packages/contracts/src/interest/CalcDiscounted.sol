// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title CalcDiscounted
 * @dev This library implements the calculation of discounted principal, and recovery of the original principal using the Price mechanism.
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
 *
 * @dev all functions are internal to be deployed in the same contract as caller (not a separate one)
 */
library CalcDiscounted {
    using Math for uint256;

    /**
     * @notice Calculates the discounted principal by dividing the principal by the price.
     * @param principal The initial principal amount.
     * @param price The ratio of Discounted to Principal
     * @return discounted The discounted principal amount.
     */
    function calcDiscounted(uint256 principal, uint256 price, uint256 scale)
        internal
        pure
        returns (uint256 discounted)
    {
        return principal.mulDiv(scale, price, Math.Rounding.Floor); // Discounted = Principal / Price
    }

    /**
     * @notice Recovers the original principal from a discounted value by multiplying it with the price.
     * @param discounted The discounted principal amount.
     * @param price The ratio of Discounted to Principal
     * @return principal The recovered original principal amount.
     */
    function calcPrincipalFromDiscounted(uint256 discounted, uint256 price, uint256 scale)
        internal
        pure
        returns (uint256 principal)
    {
        return discounted.mulDiv(price, scale, Math.Rounding.Floor); // Principal = Discounted * Price
    }
}
