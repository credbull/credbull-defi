// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";

contract LiquidContinuousMultiTokenVaultTest is LiquidContinuousMultiTokenVaultTestBase {
    function test__RequestRedeemTest__RedeemAtTenor() public {
        testVaultAtOffsets(
            alice,
            _liquidVault,
            TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: _liquidVault.TENOR() })
        );
    }

    function test__LiquidContinuousVaultTest__RedeemBeforeTenor() public {
        testVaultAtOffsets(
            bob,
            _liquidVault,
            TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: _liquidVault.TENOR() })
        );
    }

    function test__LiquidContinuousVaultTest__Load() public {
        vm.skip(true); // load test - should only be run during perf testing

        uint256 principal = 100_000 * _scale;

        _loadTestVault(_liquidVault, principal, 1, 1_000); // 1,000 works, 1800 too much for the vm
    }

    function test__LiquidContinuousVaultTest__BuyAndSell() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault; // _createLiquidContinueMultiTokenVault(_vaultParams);

        TestParam memory testParams = TestParam({ principal: 2_000 * _scale, depositPeriod: 11, redeemPeriod: 70 });

        uint256 assetStartBalance = _asset.balanceOf(alice);

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share

        // ---------------- buy (deposit) ----------------
        _warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(alice);
        _asset.approve(address(liquidVault), testParams.principal); // grant the vault allowance
        liquidVault.requestBuy(testParams.principal);
        vm.stopPrank();

        assertEq(
            testParams.principal,
            _asset.balanceOf(address(liquidVault)),
            "vault should have the principal worth of assets"
        );
        assertEq(
            testParams.principal,
            liquidVault.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );

        // ---------------- requestSell (requestRedeem) ----------------
        _warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        // requestSell
        vm.prank(alice);
        uint256 requestId = liquidVault.requestSell(sharesAmount);
        assertEq(
            sharesAmount,
            liquidVault.unlockRequestAmountByDepositPeriod(alice, testParams.depositPeriod),
            "unlockRequest should be created"
        );

        // ---------------- sell (redeem) ----------------
        uint256 expectedYield = _expectedReturns(sharesAmount, liquidVault, testParams);
        assertEq(33_333333, expectedYield, "expected returns incorrect");
        _transferFromTokenOwner(_asset, address(liquidVault), expectedYield); // fund the vault to cover redeem

        _warpToPeriod(liquidVault, testParams.redeemPeriod);

        vm.prank(alice);
        liquidVault.executeSell(alice, requestId, testParams.principal + expectedYield, sharesAmount);

        assertEq(0, liquidVault.balanceOf(alice, testParams.depositPeriod), "user should have no shares remaining");
        assertEq(
            assetStartBalance + expectedYield,
            _asset.balanceOf(alice),
            "user should have received principal + yield back"
        );
    }

    // Scenario: Calculating returns for a standard investment
    function test__LiquidContinuousVaultTest__50k_Returns() public view {
        uint256 deposit = 50_000 * _scale;

        // verify returns
        uint256 actualYield = _liquidVault.calcYield(deposit, 0, _liquidVault.TENOR() - 1);
        assertEq(416_666666, actualYield, "interest not correct for $50k deposit after 30 days");

        // verify principal + returns
        uint256 actualShares = _liquidVault.convertToShares(deposit);
        uint256 actualReturns = _liquidVault.convertToAssetsForDepositPeriod(actualShares, 0, _liquidVault.TENOR() - 1);
        assertEq(50_416_666666, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }
}
