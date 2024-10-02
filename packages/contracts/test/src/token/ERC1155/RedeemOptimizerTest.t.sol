// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

import { MultiTokenVaultTest } from "@test/src/token/ERC1155/MultiTokenVaultTest.t.sol";
import { MultiTokenVaultDailyPeriods } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriods.t.sol";

contract RedeemOptimizerTest is MultiTokenVaultTest {
    function setUp() public override {
        super.setUp();
    }

    // Scenario: Calculating returns for a standard investment
    function test__RedeemOptimizerTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;

        // setup
        IMultiTokenVault multiTokenVault = new MultiTokenVaultDailyPeriods(asset, assetToSharesRatio, 10);
        RedeemOptimizerFIFO redeemOptimizer = new RedeemOptimizerFIFO();

        // verify deposit - period 1
        uint256 deposit1Shares = _testDepositOnly(alice, multiTokenVault, deposit1TestParams);
        uint256 deposit2Shares = _testDepositOnly(alice, multiTokenVault, deposit2TestParams);
        uint256 deposit3Shares = _testDepositOnly(alice, multiTokenVault, deposit3TestParams);

        uint256 totalDepositShares = deposit1Shares + deposit2Shares + deposit3Shares;

        // warp vault to last depositPeriod
        _warpToPeriod(multiTokenVault, deposit3TestParams.depositPeriod);

        // check full redeem
        (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimizeRedeem(multiTokenVault, alice, totalDepositShares);

        assertEq(3, depositPeriods.length, "depositPeriods wrong length - full redeem");
        assertEq(3, sharesAtPeriods.length, "sharesAtPeriods wrong length - full redeem");

        assertEq(deposit1TestParams.depositPeriod, depositPeriods[0]);
        assertEq(deposit1Shares, sharesAtPeriods[0]);
    }
}

contract RedeemOptimizerFIFO is IRedeemOptimizer {
    error RedeemOptimizerFIFO__InvalidPeriodRange(uint256 fromPeriod, uint256 toPeriod);
    error RedeemOptimizerFIFO__FuturePeriodNotAllowed(uint256 toPeriod, uint256 currentPeriod);

    function optimizeRedeem(IMultiTokenVault vault, address owner, uint256 shares)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _sharesAtPeriods(vault, owner, shares, 0, vault.currentPeriodsElapsed());
    }

    // TODO - confirm whether assets here is the "principal" (easier) or the "total desired withdraw" (trickier)
    function optimizeWithdraw(IMultiTokenVault vault, address owner, uint256 assets)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _sharesAtPeriods(vault, owner, assets, 0, vault.currentPeriodsElapsed());
    }

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

    /**
     * @notice Counts the number of deposit periods with non-zero balances, up to a maximum number of shares.
     * @param owner The address holding the shares.
     * @param maxShares The maximum number of shares to consider when counting periods.
     * @param fromPeriod The starting deposit period (inclusive).
     * @param toPeriod The ending deposit period (inclusive).
     * @return numPeriodsWithBalance The number of periods with non-zero shares, up to the maxShares limit.
     */
    function _numPeriodsWithBalance(
        IMultiTokenVault vault,
        address owner,
        uint256 maxShares,
        uint256 fromPeriod,
        uint256 toPeriod
    ) internal view returns (uint256 numPeriodsWithBalance, uint256 sharesCollected) {
        if (fromPeriod > toPeriod) {
            revert RedeemOptimizerFIFO__InvalidPeriodRange(fromPeriod, toPeriod);
        }

        uint256 currentPeriod = vault.currentPeriodsElapsed();
        if (toPeriod > currentPeriod) {
            revert RedeemOptimizerFIFO__FuturePeriodNotAllowed(toPeriod, currentPeriod);
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
