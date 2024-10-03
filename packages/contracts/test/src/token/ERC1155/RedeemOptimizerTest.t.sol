// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

import { MultiTokenVaultTest } from "@test/src/token/ERC1155/MultiTokenVaultTest.t.sol";

contract RedeemOptimizerTest is MultiTokenVaultTest {
    function setUp() public override {
        super.setUp();
    }

    // Scenario: Calculating returns for a standard investment
    function test__RedeemOptimizerTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO();

        (uint256[] memory depositPeriods, uint256[] memory depositShares) = _testDeposits(alice, multiTokenVault); // make a few deposits
        uint256 totalDepositShares = depositShares[0] + depositShares[1] + depositShares[2];

        // warp vault ahead redemPeriod
        uint256 redeemPeriod = deposit3TestParams.redeemPeriod;
        _warpToPeriod(multiTokenVault, redeemPeriod);

        // check full redeem
        (uint256[] memory redeemDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimizeRedeemShares(multiTokenVault, alice, totalDepositShares, redeemPeriod);

        assertEq(3, redeemDepositPeriods.length, "depositPeriods wrong length - full redeem");
        assertEq(3, sharesAtPeriods.length, "sharesAtPeriods wrong length - full redeem");

        assertEq(deposit1TestParams.depositPeriod, redeemDepositPeriods[0], "optimizeRedeem - wrong depositPeriod");
        assertEq(depositShares[0], sharesAtPeriods[0], "optimizeRedeem - wrong shares");

        // TODO - check the other depositPeriods

        uint256[] memory expectedAssetsAtPeriods =
            multiTokenVault.convertToAssetsForDepositPeriods(depositShares, depositPeriods, redeemPeriod);

        (uint256[] memory withdrawDepositPeriods, uint256[] memory actualAssetsAtPeriods) =
            redeemOptimizer.optimizeWithdrawAssets(multiTokenVault, alice, totalDepositShares, redeemPeriod);

        assertEq(3, withdrawDepositPeriods.length, "depositPeriods wrong length - full redeem");
        assertEq(3, actualAssetsAtPeriods.length, "sharesAtPeriods wrong length - full redeem");

        assertEq(deposit1TestParams.depositPeriod, withdrawDepositPeriods[0], "optimizeWithdraw - wrong depositPeriod");
        assertEq(expectedAssetsAtPeriods[0], actualAssetsAtPeriods[0], "optimizeWithdraw - wrong assets");

        // TODO - check the other withdrawPeriods
    }

    function _testDeposits(address receiver, IMultiTokenVault vault)
        internal
        returns (uint256[] memory depositPeriods_, uint256[] memory shares_)
    {
        uint256[] memory depositPeriods = new uint256[](3);
        uint256[] memory shares = new uint256[](3);

        depositPeriods[0] = deposit1TestParams.depositPeriod;
        depositPeriods[1] = deposit2TestParams.depositPeriod;
        depositPeriods[2] = deposit3TestParams.depositPeriod;

        shares[0] = _testDepositOnly(receiver, vault, deposit1TestParams);
        shares[1] = _testDepositOnly(receiver, vault, deposit2TestParams);
        shares[2] = _testDepositOnly(receiver, vault, deposit3TestParams);

        return (depositPeriods, shares);
    }
}
