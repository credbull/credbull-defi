// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IMTVTestParamArray } from "@test/test/token/ERC1155/IMTVTestParamArray.t.sol";

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

    function test__LiquidContinuousVaultTest__DepositRedeem() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault; // _createLiquidContinueMultiTokenVault(_vaultParams);

        TestParam memory testParams = TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

        uint256 assetStartBalance = _asset.balanceOf(alice);

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share

        // ---------------- deposit ----------------
        _warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(alice);
        _asset.approve(address(liquidVault), testParams.principal); // grant the vault allowance
        liquidVault.requestDeposit(testParams.principal, alice, alice);
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

        // ---------------- requestRedeem ----------------
        _warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        // requestSell
        vm.prank(alice);
        liquidVault.requestRedeem(sharesAmount, alice, alice);
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
        liquidVault.redeem(testParams.principal, alice, alice);

        assertEq(0, liquidVault.balanceOf(alice, testParams.depositPeriod), "user should have no shares remaining");
        assertEq(
            assetStartBalance + expectedYield,
            _asset.balanceOf(alice),
            "user should have received principal + yield back"
        );
    }

    function test__LiquidContinuousVaultTest__WithdrawAssetFromVault() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;

        TestParam memory testParams = TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });
        address assetManager = getAssetManager();

        // ---------------- deposit ----------------
        _warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(alice);
        _asset.approve(address(liquidVault), testParams.principal); // grant the vault allowance
        liquidVault.requestDeposit(testParams.principal, alice, alice);
        vm.stopPrank();

        uint256 assetManagerStartBalance = _asset.balanceOf(assetManager);
        uint256 vaultStartBalance = _asset.balanceOf(address(liquidVault));

        // ---------------- WithdrawAssetFrom Vault ----------------
        vm.prank(assetManager);
        liquidVault.withdrawAsset(assetManager, vaultStartBalance);

        //assert balance
        assertEq(assetManagerStartBalance + vaultStartBalance, _asset.balanceOf(assetManager));
    }

    function test__LiquidContinuousVaultTest__RequestRedeemTwice() public {
        uint256 redeemPeriod = 32;
        uint256 requestRedeemPeriod = redeemPeriod - _liquidVault.noticePeriod();

        IMTVTestParamArray testParamsArray = new IMTVTestParamArray();
        testParamsArray.addTestParam(
            TestParam({ principal: 101 * _scale, depositPeriod: 1, redeemPeriod: redeemPeriod })
        );
        testParamsArray.addTestParam(
            TestParam({ principal: 202 * _scale, depositPeriod: 2, redeemPeriod: redeemPeriod })
        );
        testParamsArray.addTestParam(
            TestParam({ principal: 303 * _scale, depositPeriod: 3, redeemPeriod: redeemPeriod })
        );
        testParamsArray.addTestParam(
            TestParam({ principal: 404 * _scale, depositPeriod: 4, redeemPeriod: redeemPeriod })
        );

        _testDepositOnly(alice, _liquidVault, testParamsArray.all());

        // warp to the request redeem period
        _warpToPeriod(_liquidVault, requestRedeemPeriod);

        // ------------ requestRedeem #1 ------------
        uint256 oneShare = 1 * _scale; // a little over the first deposit shares
        uint256 sharesToRedeem1 = testParamsArray.get(0).principal + oneShare; // a little over the first deposit shares
        vm.prank(alice);
        // uint256 requestId1 = _liquidVault.requestSell(sharesToRedeem1);
        uint256 requestId1 = _liquidVault.requestRedeem(sharesToRedeem1, alice, alice);
        (uint256[] memory unlockDepositPeriods1, uint256[] memory unlockShares1) =
            _liquidVault.unlockRequests(alice, requestId1);

        assertEq(2, unlockDepositPeriods1.length, "unlock request1 depositPeriods incorrect");
        assertEq(
            testParamsArray.get(0).depositPeriod, unlockDepositPeriods1[0], "wrong unlock request1 deposit period - 0"
        );
        assertEq(testParamsArray.get(0).principal, unlockShares1[0], "wrong unlock request1 shares - 0");

        assertEq(
            testParamsArray.get(1).depositPeriod, unlockDepositPeriods1[1], "wrong unlock request1 deposit period - 1"
        );
        assertEq(oneShare, unlockShares1[1], "wrong unlock request1 shares - 1");

        // ------------ requestRedeem #2 ------------

        uint256 sharesToRedeem2 = testParamsArray.get(1).principal; // a little over the second deposit shares
        vm.prank(alice);
        uint256 requestId2 = _liquidVault.requestRedeem(sharesToRedeem2, alice, alice);
        (uint256[] memory unlockDepositPeriods2, uint256[] memory unlockShares2) =
            _liquidVault.unlockRequests(alice, requestId2);

        assertEq(3, unlockDepositPeriods2.length, "unlock request2 depositPeriods incorrect");
        assertEq(
            testParamsArray.get(0).depositPeriod, unlockDepositPeriods2[0], "wrong unlock request2 deposit period - 0"
        );
        assertEq(testParamsArray.get(0).principal, unlockShares2[0], "wrong unlock request2 shares - 0");
        assertEq(
            testParamsArray.get(1).depositPeriod, unlockDepositPeriods2[1], "wrong unlock request2 deposit period - 1"
        );
        assertEq(testParamsArray.get(1).principal, unlockShares2[1], "wrong unlock request2 shares - 1");
        assertEq(
            testParamsArray.get(2).depositPeriod, unlockDepositPeriods2[2], "wrong unlock request2 deposit period - 2"
        );
        assertEq(oneShare, unlockShares2[2], "wrong unlock request2 shares - 2");
    }

    function test__LiquidContinuousVaultTest__ShouldRevertWithdrawAssetIfNotOwner() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;
        address randomWallet = makeAddr("randomWallet");
        vm.startPrank(randomWallet);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, randomWallet, liquidVault.ASSET_MANAGER_ROLE()
            )
        );
        liquidVault.withdrawAsset(randomWallet, 1000);
        vm.stopPrank();
    }

    // Scenario: Calculating returns for a standard investment
    function test__LiquidContinuousVaultTest__50k_Returns() public view {
        uint256 deposit = 50_000 * _scale;

        // verify returns
        uint256 actualYield = _liquidVault.calcYield(deposit, 0, _liquidVault.TENOR());
        assertEq(416_666666, actualYield, "interest not correct for $50k deposit after 30 days");

        // verify principal + returns
        uint256 actualShares = _liquidVault.convertToShares(deposit);
        uint256 actualReturns = _liquidVault.convertToAssetsForDepositPeriod(actualShares, 0, _liquidVault.TENOR());
        assertEq(50_416_666666, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }
}
