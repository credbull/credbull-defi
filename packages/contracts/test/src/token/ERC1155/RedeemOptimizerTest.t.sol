// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
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
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO();

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
