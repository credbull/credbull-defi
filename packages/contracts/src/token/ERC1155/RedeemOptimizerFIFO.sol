// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { RedeemOptimizer } from "@credbull/token/ERC1155/RedeemOptimizer.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title RedeemOptimizerFIFO
 * @dev Optimizes the redemption of shares using a FIFO strategy.
 */
contract RedeemOptimizerFIFO is RedeemOptimizer {
    using Math for uint256;

    constructor(OptimizerBasis defaultBasis, uint256 startDepositPeriod)
        RedeemOptimizer(defaultBasis, startDepositPeriod)
    { }

    /// @notice Returns deposit periods and corresponding amounts (shares or assets) within the specified range.
    function _findAmount(IMultiTokenVault vault, OptimizerParams memory optimizerParams)
        internal
        view
        override
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        uint256 noOfPeriods = (optimizerParams.toDepositPeriod - optimizerParams.fromDepositPeriod) + 1;
        depositPeriods = new uint256[](noOfPeriods);
        sharesAtPeriods = new uint256[](noOfPeriods);
        uint256 arrayIndex = 0;
        uint256 amountFound = 0;

        // Iterate over the from/to period range, inclusive of from and to.
        for (
            uint256 depositPeriod = optimizerParams.fromDepositPeriod;
            depositPeriod <= optimizerParams.toDepositPeriod;
            ++depositPeriod
        ) {
            uint256 sharesAtPeriod = vault.sharesAtPeriod(optimizerParams.owner, depositPeriod);
            uint256 amountAtPeriod = optimizerParams.optimizerBasis == OptimizerBasis.Shares
                ? sharesAtPeriod
                : vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, optimizerParams.redeemPeriod);

            // If there is an Amount, store the value.
            if (amountAtPeriod > 0) {
                depositPeriods[arrayIndex] = depositPeriod;

                // check if we will go "over" the Amount To Find.
                if (amountFound + amountAtPeriod > optimizerParams.amountToFind) {
                    // we only need the amount that brings us to amountToFind
                    uint256 amountToInclude = optimizerParams.amountToFind - amountFound;

                    // only include equivalent amount of shares for the amountToInclude assets
                    // in the assets case, the amounts include principal AND returns.  we want the shares on deposit,
                    // which is the principal only.
                    // use this ratio: partialShares / totalShares = partialAssets / totalAssets
                    //                 partialShares = (partialAssets * totalShares) / totalAssets
                    sharesAtPeriods[arrayIndex] = optimizerParams.optimizerBasis == OptimizerBasis.Shares
                        // amount is shares, amountToInclude already correct
                        ? amountToInclude
                        // amount is assets, calc the correct shares
                        : amountToInclude.mulDiv(sharesAtPeriod, amountAtPeriod);

                    // optimization succeeded - return here to be explicit we exit the function at this point
                    return _trimToSize(arrayIndex + 1, depositPeriods, sharesAtPeriods);
                } else {
                    sharesAtPeriods[arrayIndex] = sharesAtPeriod;
                }

                amountFound += amountAtPeriod;
                arrayIndex++;
            }
        }

        if (amountFound < optimizerParams.amountToFind) {
            revert RedeemOptimizer__OptimizerFailed(amountFound, optimizerParams.amountToFind);
        }

        return _trimToSize(arrayIndex, depositPeriods, sharesAtPeriods);
    }
}
