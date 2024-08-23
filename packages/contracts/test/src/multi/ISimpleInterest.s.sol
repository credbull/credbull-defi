// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Extension to Interface Vault Standard
 */
interface ISimpleInterest {
    function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 interest);

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 principal);
}
