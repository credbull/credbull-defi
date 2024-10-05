// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";

import { console } from "forge-std/console.sol";

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
        console.log("optimizeRedeemShares(): Shares= %d, Redeem Period= %d", shares, redeemPeriod);
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
        console.log("optimizeWithdrawAssets(): Assets= %d, Redeem Period= %d", assets, redeemPeriod);

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

        console.log("_amountsAtPeriods(): Current Period= %d", vault.currentPeriodsElapsed());

        uint256 currentPeriod = vault.currentPeriodsElapsed();
        if (toDepositPeriod > currentPeriod) {
            revert RedeemOptimizer__FutureToDepositPeriod(toDepositPeriod, currentPeriod);
        }

        console.log(
            "_amountsAtPeriods(): MaxAmount= %d, From= %d, To= %d", maxAmount, fromDepositPeriod, toDepositPeriod
        );
        console.log(
            "_amountsAtPeriods(): No Of Periods= %d, Amount Type= ",
            (toDepositPeriod - fromDepositPeriod) + 1,
            amountType == AmountType.Shares ? "Shares" : "AssetWithReturns"
        );

        // Query the vault to locate ...
        // NOTE (JL,2024-10-04): The number of periods is inclusive.
        uint256[] memory cacheDepositPeriods = new uint256[]((toDepositPeriod - fromDepositPeriod) + 1);
        uint256[] memory cacheAmountAtPeriods = new uint256[]((toDepositPeriod - fromDepositPeriod) + 1);
        uint256 arrayIndex = 0;
        uint256 amountFound = 0;

        for (uint256 depositPeriod = fromDepositPeriod; depositPeriod <= toDepositPeriod; ++depositPeriod) {
            uint256 sharesAtPeriod = vault.balanceOf(owner, depositPeriod);
            uint256 amountAtPeriod = amountType == AmountType.Shares
                ? sharesAtPeriod
                : vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, redeemPeriod);

            if (amountAtPeriod > 0) {
                console.log(
                    "_amountsAtPeriods(): Period= %d, Shares= %d, Amount= %d",
                    depositPeriod,
                    sharesAtPeriod,
                    amountAtPeriod
                );
                cacheDepositPeriods[arrayIndex] = depositPeriod;

                // check if we will go "over" the max amount
                if ((amountFound + amountAtPeriod) > amountToFind) {
                    cacheAmountAtPeriods[arrayIndex++] = maxAmount - amountFound; // include only the partial amount
                    console.log("_amountsAtPeriods(): Partial= %d", cacheAmountAtPeriods[arrayIndex - 1]);
                    break; // we're done, no need to keep looping
                } else {
                    cacheAmountAtPeriods[arrayIndex] = amountAtPeriod;
                }

                amountFound += cacheAmountAtPeriods[arrayIndex];
                arrayIndex++;
            }
        }

        if (amountFound < amountToFind) {
            revert RedeemOptimizer__OptimizerFailed(amountFound, amountToFind);
        }

        return _trimToSize(arrayIndex, cacheDepositPeriods, cacheAmountAtPeriods);
    }

    function _trimToSize(uint256 toSize, uint256[] memory toTrim1, uint256[] memory toTrim2)
        private
        pure
        returns (uint256[] memory trimmed1, uint256[] memory trimmed2)
    {
        console.log("_trimToSize(): Size= %d", toSize);

        trimmed1 = new uint256[](toSize);
        trimmed2 = new uint256[](toSize);
        for (uint256 i = 0; i < toSize; i++) {
            console.log("trimToSize():  %d, Deposit Period= %d, Amount= %d", i, toTrim1[i], toTrim2[i]);
            trimmed1[i] = toTrim1[i];
            trimmed2[i] = toTrim2[i];
        }
    }
}
