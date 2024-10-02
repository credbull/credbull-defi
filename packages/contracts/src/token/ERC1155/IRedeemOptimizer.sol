// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

/**
 * @title IRedeemOptimizer
 * @notice Interface for optimizing redemptions and withdrawals across deposit periods.
 */
interface IRedeemOptimizer {
    /**
     * @notice Finds optimal deposit periods and shares to redeem.
     * @param shares The total shares to redeem.
     * @return depositPeriods Array of deposit periods to redeem from.
     * @return sharesAtPeriods Array of share amounts to redeem for each deposit period.
     */
    function optimizeRedeem(IMultiTokenVault vault, address owner, uint256 shares)
        external
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);

    /**
     * @notice Finds optimal deposit periods and shares to redeem for a given asset amount.
     * @param assets The total asset amount to withdraw.
     * @return depositPeriods Array of deposit periods to redeem from.
     * @return sharesAtPeriods Array of share amounts to redeem for each deposit period.
     */
    function optimizeWithdraw(IMultiTokenVault vault, address owner, uint256 assets)
        external
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
}
