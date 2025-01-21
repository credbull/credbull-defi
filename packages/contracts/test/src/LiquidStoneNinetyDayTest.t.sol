// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { BaseVault } from "@credbull/yield/BaseVault.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";

import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";

import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract DeployLiquidStoneNinetyDay is DeployLiquidMultiTokenVault {
    function _createVaultParams(
        BaseVault.VaultAuth memory vaultAuth,
        IERC20Metadata asset,
        IYieldStrategy yieldStrategy,
        IRedeemOptimizer redeemOptimizer
    ) public view override returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_) {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            super._createVaultParams(vaultAuth, asset, yieldStrategy, redeemOptimizer);

        uint256 scale = 10 ** asset.decimals();
        vaultParams.contextParams.tenor = 90;
        vaultParams.redeemNoticePeriod = 0;
        vaultParams.contextParams.fullRateScaled = 10 * scale;
        vaultParams.contextParams.initialReducedRate.interestRate = 0; // zero for less than tenor

        return vaultParams;
    }
}

contract LiquidStoneNinetyDayTest is LiquidContinuousMultiTokenVaultTestBase {
    using TestParamSet for TestParamSet.TestParam[];

    function setUp() public virtual override {
        DeployLiquidMultiTokenVault _deployVault = new DeployLiquidStoneNinetyDay();
        _liquidVault = _deployVault.run(_vaultAuth);

        // warp to a "real time" time rather than block.timestamp=1
        vm.warp(_liquidVault._vaultStartTimestamp() + 1);

        _asset = IERC20Metadata(_liquidVault.asset());
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, _vaultAuth.owner, alice, 100_000 * _scale);
        _transferAndAssert(_asset, _vaultAuth.owner, bob, 100_000 * _scale);
    }

    function test__LiquidStoneNinetyDay__VerifyDeployTenor() public view {
        assertEq(90, _liquidVault.TENOR(), "tenor incorrect");
    }

    // TODO - need to implement and test for RetainedAssetsReceive1APY

    function test__LiquidStoneNinetyDay__RedeemFullTenor() public {
        uint256 depositPeriod = 5;
        uint256 redeemPeriod = depositPeriod + _liquidVault.TENOR();
        uint256 principal = 105 * _scale;

        TestParamSet.TestUsers memory aliceTestUsers = TestParamSet.toSingletonUsers(alice);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] =
            TestParamSet.TestParam({ principal: principal, depositPeriod: depositPeriod, redeemPeriod: redeemPeriod });

        uint256[] memory sharesAtPeriods = _testDepositOnly(aliceTestUsers, _liquidVault, testParams);

        uint256 expectedReturns = CalcSimpleInterest.calcInterest(
            principal, _liquidVault.rateScaled(), redeemPeriod - depositPeriod, _liquidVault.frequency(), _scale
        );

        _transferFromTokenOwner(_asset, address(_liquidVault), expectedReturns); // give the vault enough to cover returns

        // warp to the redeem period
        _warpToPeriod(_liquidVault, redeemPeriod);

        vm.prank(alice);
        _liquidVault.requestRedeem(sharesAtPeriods[0], alice, alice);

        vm.prank(alice);
        uint256 assets = _liquidVault.redeem(sharesAtPeriods[0], alice, alice);

        assertEq(principal + expectedReturns, assets, "wrong assets returned");
    }

    function test__LiquidStoneNinetyDay__EarlyRedemptionGivesZeroYield() public {
        uint256 depositPeriod = 25;
        uint256 earlyRedeemPeriod = depositPeriod + _liquidVault.TENOR() - 1; // less than full tenor period
        uint256 principal = 125 * _scale;

        TestParamSet.TestUsers memory aliceTestUsers = TestParamSet.toSingletonUsers(alice);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] = TestParamSet.TestParam({
            principal: principal,
            depositPeriod: depositPeriod,
            redeemPeriod: earlyRedeemPeriod
        });

        uint256[] memory sharesAtPeriods = _testDepositOnly(aliceTestUsers, _liquidVault, testParams);

        // warp to the redeem period
        _warpToPeriod(_liquidVault, earlyRedeemPeriod);

        vm.prank(alice);
        _liquidVault.requestRedeem(sharesAtPeriods[0], alice, alice);

        vm.prank(alice);
        uint256 assets = _liquidVault.redeem(sharesAtPeriods[0], alice, alice);

        assertEq(principal, assets, "early redemption should give back principal and zero returns");
    }
}
