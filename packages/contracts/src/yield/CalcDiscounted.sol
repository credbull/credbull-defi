// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title CalcDiscounted
 * @dev Implements the calculation of discounted principal and recovery of original principal using price.
 * The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are mathematical inverses.
 *
 * Example:
 * ```
 * uint256 originalPrincipal = 200;
 * uint256 price = 2;
 *
 * uint256 discountedValue = calcDiscounted(originalPrincipal, price); // 200 / 2 = 100
 * uint256 recoveredPrincipal = calcPrincipalFromDiscounted(discountedValue, price); // 100 * 2 = 200
 *
 * assert(recoveredPrincipal == originalPrincipal);
 * ```
 */
library CalcDiscounted {
    using Math for uint256;

    /// @notice Returns the discounted principal by dividing `principal` by `price`.
    function calcDiscounted(uint256 principal, uint256 price, uint256 scale)
        internal
        pure
        returns (uint256 discounted)
    {
        return principal.mulDiv(scale, price, Math.Rounding.Floor);
    }

    /// @notice Recovers the original principal by multiplying `discounted` with `price`.
    function calcPrincipalFromDiscounted(uint256 discounted, uint256 price, uint256 scale)
        internal
        pure
        returns (uint256 principal)
    {
        return discounted.mulDiv(price, scale, Math.Rounding.Floor);
    }
}
