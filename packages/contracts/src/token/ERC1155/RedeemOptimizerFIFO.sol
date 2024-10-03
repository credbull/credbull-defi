// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";

/**
 * @title RedeemOptimizerFIFO
 * @dev Optimizes the redemption of shares using a FIFO strategy.
 */
contract RedeemOptimizerFIFO is IRedeemOptimizer {
    error RedeemOptimizer__InvalidPeriodRange(uint256 fromPeriod, uint256 toPeriod);
    error RedeemOptimizer__FuturePeriodNotAllowed(uint256 toPeriod, uint256 currentPeriod);

    enum AmountType {
        Shares,
        AssetsWithReturns
    }

    uint256 public _fromDepositPeriod = 0;

    /// @inheritdoc IRedeemOptimizer
    function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _amountsAtPeriods(
            vault, owner, shares, _fromDepositPeriod, vault.currentPeriodsElapsed(), redeemPeriod, AmountType.Shares
        );
    }

    /// @inheritdoc IRedeemOptimizer
    /// @dev - assets include deposit (principal) and any returns up to the redeem period
    // TODO - confirm whether returns are calculated on the requestRedeem period or redeemPeriod ?
    function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _amountsAtPeriods(
            vault,
            owner,
            assets,
            _fromDepositPeriod,
            vault.currentPeriodsElapsed(),
            redeemPeriod,
            AmountType.AssetsWithReturns
        );
    }

    /// @notice Returns deposit periods and corresponding amounts (shares or assets) within the specified range.
    function _amountsAtPeriods(
        IMultiTokenVault vault,
        address owner,
        uint256 maxAmount,
        uint256 fromDepositPeriod,
        uint256 toDepositPeriod,
        uint256 redeemPeriod,
        AmountType amountType
    ) internal view returns (uint256[] memory depositPeriods, uint256[] memory amountAtPeriods) {
        if (fromDepositPeriod > toDepositPeriod) {
            revert RedeemOptimizer__InvalidPeriodRange(fromDepositPeriod, toDepositPeriod);
        }

        uint256 currentPeriod = vault.currentPeriodsElapsed();
        if (toDepositPeriod > currentPeriod) {
            revert RedeemOptimizer__FuturePeriodNotAllowed(toDepositPeriod, currentPeriod);
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
        uint256 amountCollected = 0;

        for (uint256 depositPeriod = fromDepositPeriod; depositPeriod <= toDepositPeriod; ++depositPeriod) {
            uint256 sharesAtPeriod = vault.balanceOf(owner, depositPeriod);

            uint256 amountAtPeriod = amountType == AmountType.Shares
                ? sharesAtPeriod
                : vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, redeemPeriod);

            if (amountAtPeriod > 0) {
                depositPeriods[arrayIndex] = depositPeriod;

                // check if we will go "over" the max amount
                if ((amountCollected + amountAtPeriod) > maxAmount) {
                    amountAtPeriods[arrayIndex] = maxAmount - amountCollected; // include only the partial amount

                    return (depositPeriods, amountAtPeriods); // we're done, no need to keep looping
                } else {
                    amountAtPeriods[arrayIndex] = amountAtPeriod;
                }

                amountCollected += amountAtPeriods[arrayIndex];
                arrayIndex++;
            }
        }

        // TODO - if the sharesCollected is less than the maxShares - should we revert or return what we have?

        return (depositPeriods, amountAtPeriods);
    }
}
