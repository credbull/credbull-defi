// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ISimpleInterest } from "./ISimpleInterest.s.sol";

/**
 * @dev Extension to Interface Vault Standard
 */
interface IERC4626Interest {
    function convertToSharesAtPeriod(uint256 assets, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 shares);

    function convertToAssetsAtPeriod(uint256 shares, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 assets);

    function convertToPrincipalAtPeriod(uint256 shares, uint256 numTimePeriodsElapsed)
        external
        view
        returns (uint256 assets);

    function calculateCycle(uint256 numTimePeriods) external view returns (uint256 cycle);
}
