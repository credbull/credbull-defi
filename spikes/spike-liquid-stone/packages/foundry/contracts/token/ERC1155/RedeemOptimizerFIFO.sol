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

    /// @inheritdoc IRedeemOptimizer
    function optimizeRedeem(IMultiTokenVault vault, address owner, uint256 shares)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _sharesAtPeriods(vault, owner, shares, 0, vault.currentPeriodsElapsed());
    }

    // TODO - confirm whether assets here is the "principal" (easier) or the "total desired withdraw" (trickier)
    /// @inheritdoc IRedeemOptimizer
    function optimizeWithdraw(IMultiTokenVault vault, address owner, uint256 assets)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _sharesAtPeriods(vault, owner, assets, 0, vault.currentPeriodsElapsed());
    }

    /// @notice Returns deposit periods and corresponding shares within the specified range.
    function _sharesAtPeriods(
        IMultiTokenVault vault,
        address owner,
        uint256 maxShares,
        uint256 fromPeriod,
        uint256 toPeriod
    ) internal view returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods_) {
        // count periods with a non-zero balance
        (uint256 numPeriodsWithBalance,) = _numPeriodsWithBalance(vault, owner, maxShares, fromPeriod, toPeriod);

        // TODO - if the sharesCollected is less than the maxShares - should we revert or continue?

        depositPeriods = new uint256[](numPeriodsWithBalance);
        sharesAtPeriods_ = new uint256[](numPeriodsWithBalance);

        // populate arrays
        uint256 arrayIndex = 0;
        uint256 sharesCollected_ = 0;

        for (uint256 i = fromPeriod; i <= toPeriod; i++) {
            uint256 sharesAtPeriod = vault.balanceOf(owner, i);

            if (sharesAtPeriod > 0) {
                depositPeriods[arrayIndex] = i;

                uint256 shares =
                    sharesAtPeriod + sharesCollected_ <= maxShares ? sharesAtPeriod : maxShares - sharesCollected_;

                sharesAtPeriods_[arrayIndex] = shares;

                arrayIndex++;
            }
        }
    }

    /// @notice Counts periods with non-zero shares and the total collected shares.
    function _numPeriodsWithBalance(
        IMultiTokenVault vault,
        address owner,
        uint256 maxShares,
        uint256 fromPeriod,
        uint256 toPeriod
    ) internal view returns (uint256 numPeriodsWithBalance, uint256 sharesCollected) {
        if (fromPeriod > toPeriod) {
            revert RedeemOptimizer__InvalidPeriodRange(fromPeriod, toPeriod);
        }

        uint256 currentPeriod = vault.currentPeriodsElapsed();
        if (toPeriod > currentPeriod) {
            revert RedeemOptimizer__FuturePeriodNotAllowed(toPeriod, currentPeriod);
        }

        uint256 numPeriodsWithBalance_ = 0;
        uint256 sharesCollected_ = 0;

        for (uint256 i = fromPeriod; i <= toPeriod; i++) {
            uint256 sharesAtPeriod = vault.balanceOf(owner, i);

            if (sharesAtPeriod > 0) {
                numPeriodsWithBalance_++;
                sharesCollected_ += sharesAtPeriod;
            }

            if (sharesCollected_ >= maxShares) {
                return (numPeriodsWithBalance_, maxShares);
            }
        }

        return (numPeriodsWithBalance_, sharesCollected);
    }
}
