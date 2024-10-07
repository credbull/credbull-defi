// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

/**
 * @title IRedeemOptimizer
 * @notice Interface for optimizing redemptions and withdrawals across deposit periods.
 */
interface IRedeemOptimizer {
    struct OptimizerParams {
        address owner;
        uint256 amountToFind;
        uint256 fromDepositPeriod;
        uint256 toDepositPeriod;
        uint256 redeemPeriod;
        OptimizerBasis optimizerBasis;
    }

    enum OptimizerBasis {
        Shares,
        AssetsWithReturns
    }

    /**
     * @notice Finds optimal deposit periods and shares to redeem.  Optimizer chooses shares or asset basis.
     * @return depositPeriods Array of deposit periods to redeem from.
     * @return sharesAtPeriods Array of share amounts to redeem for each deposit period.
     */
    function optimize(IMultiTokenVault vault, address owner, uint256 shares, uint256 assets, uint256 redeemPeriod)
        external
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);

    /**
     * @notice Finds optimal deposit periods and shares to redeem for a given share amount and redeemPeriod
     * @return depositPeriods Array of deposit periods to redeem from.
     * @return sharesAtPeriods Array of share amounts to redeem for each deposit period.
     */
    function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
        external
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);

    /**
     * @notice Finds optimal deposit periods and shares to withdraw for a given asset amount and redeemPeriod
     * @return depositPeriods Array of deposit periods to redeem from.
     * @return sharesAtPeriods Array of share amounts to redeem for each deposit period.
     */
    function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
        external
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
}
