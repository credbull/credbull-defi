// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";

/**
 * @title RedeemOptimizerFIFO
 * @dev Optimizes the redemption of shares using a FIFO strategy.
 */
contract RedeemOptimizerFIFO is IRedeemOptimizer {
    error RedeemOptimizer__InvalidDepositPeriodRange(uint256 fromPeriod, uint256 toPeriod);
    error RedeemOptimizer__FutureToDepositPeriod(uint256 toPeriod, uint256 currentPeriod);
    error RedeemOptimizer__OptimizerFailed(uint256 amountFound, uint256 amountToFind);

    enum AmountType {
        Shares,
        AssetsWithReturns
    }

    uint256 public immutable START_DEPOSIT_PERIOD = 0;

    constructor(uint256 startDepositPeriod) {
        START_DEPOSIT_PERIOD = startDepositPeriod;
    }

    /// @inheritdoc IRedeemOptimizer
    function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _findAmount(
            vault, owner, shares, START_DEPOSIT_PERIOD, vault.currentPeriodsElapsed(), redeemPeriod, AmountType.Shares
        );
    }

    /// @inheritdoc IRedeemOptimizer
    /// @dev - assets include deposit (principal) and any returns up to the redeem period
    function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _findAmount(
            vault,
            owner,
            assets,
            START_DEPOSIT_PERIOD,
            vault.currentPeriodsElapsed(),
            redeemPeriod,
            AmountType.AssetsWithReturns
        );
    }

    /// @notice Returns deposit periods and corresponding amounts (shares or assets) within the specified range.
    function _findAmount(
        IMultiTokenVault vault,
        address owner,
        uint256 amountToFind,
        uint256 fromDepositPeriod,
        uint256 toDepositPeriod,
        uint256 redeemPeriod,
        AmountType amountType
    ) internal view returns (uint256[] memory depositPeriods, uint256[] memory amountAtPeriods) {
        if (fromDepositPeriod > toDepositPeriod) {
            revert RedeemOptimizer__InvalidDepositPeriodRange(fromDepositPeriod, toDepositPeriod);
        }

        uint256 currentPeriod = vault.currentPeriodsElapsed();
        if (toDepositPeriod > currentPeriod) {
            revert RedeemOptimizer__FutureToDepositPeriod(toDepositPeriod, currentPeriod);
        }

        // first loop: check for periods with balances.  needed to correctly size our array results
        uint256 numPeriodsWithBalance = 0;
        for (uint256 depositPeriod = fromDepositPeriod; depositPeriod <= toDepositPeriod; ++depositPeriod) {
            uint256 sharesAtPeriod = vault.balanceOf(owner, depositPeriod);

            uint256 amountAtPeriod = amountType == AmountType.Shares
                ? sharesAtPeriod
                : vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, redeemPeriod);

            if (amountAtPeriod > 0) {
                numPeriodsWithBalance++;
            }
        }

        // second loop - collect and return the periods and amounts
        depositPeriods = new uint256[](numPeriodsWithBalance);
        amountAtPeriods = new uint256[](numPeriodsWithBalance);

        uint256 arrayIndex = 0;
        uint256 amountFound = 0;

        for (uint256 depositPeriod = fromDepositPeriod; depositPeriod <= toDepositPeriod; ++depositPeriod) {
            uint256 sharesAtPeriod = vault.balanceOf(owner, depositPeriod);

            uint256 amountAtPeriod = amountType == AmountType.Shares
                ? sharesAtPeriod
                : vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, redeemPeriod);

            if (amountAtPeriod > 0) {
                depositPeriods[arrayIndex] = depositPeriod;

                // check if we will go "over" the amountToFind
                if ((amountFound + amountAtPeriod) > amountToFind) {
                    amountAtPeriods[arrayIndex] = amountToFind - amountFound; // include only the amount up to amountToFind

                    return (depositPeriods, amountAtPeriods); // we're done, no need to keep looping
                } else {
                    amountAtPeriods[arrayIndex] = amountAtPeriod;
                }

                amountFound += amountAtPeriods[arrayIndex];
                arrayIndex++;
            }
        }

        if (amountFound < amountToFind) {
            revert RedeemOptimizer__OptimizerFailed(amountFound, amountToFind);
        }

        return (depositPeriods, amountAtPeriods);
    }
}
