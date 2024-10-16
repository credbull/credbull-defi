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

    function test__LiquidContinuousVaultTest__RedeemMultiPeriodsAllShares() public {
        IMTVTestParamArray depositTestParams = new IMTVTestParamArray();

        // run in some deposits
        uint256 baseDepositAmount = 100 * _scale;
        for (uint256 i = 0; i <= 10; ++i) {
            depositTestParams.addTestParam(
                TestParam({ principal: (baseDepositAmount * i) + 1 * _scale, depositPeriod: i, redeemPeriod: 1000 })
            );
        }

        _testDepositOnly(alice, _liquidVault, depositTestParams.all());

        // ------------ requestRedeem #1 -----------
        uint256 redeemPeriod1 = 31;
        IMTVTestParamArray redeemParams1 = _split(depositTestParams, 0, 2);
        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams1, 31);

        // ------------ requestRedeem #2 ------------
        uint256 redeemPeriod2 = 41;
        IMTVTestParamArray redeemParams2 = _split(depositTestParams, 3, 4);
        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams2, 41);

        // ------------ redeems ------------
        // NB - call the redeem AFTER the multiple requestRedeems.  verify multiple requestRedeems work.

        _testRedeemMultiDeposit(alice, _liquidVault, redeemParams1, redeemPeriod1);

        _testRedeemMultiDeposit(alice, _liquidVault, redeemParams2, redeemPeriod2);
    }

    function test__LiquidContinuousVaultTest__RedeemMultiPeriodsPartialShares() public {
        IMTVTestParamArray depositTestParams = new IMTVTestParamArray();

        // run in some deposits
        uint256 baseDepositAmount = 100 * _scale;
        for (uint256 i = 0; i <= 10; ++i) {
            depositTestParams.addTestParam(
                TestParam({ principal: (baseDepositAmount * i) + 1 * _scale, depositPeriod: i, redeemPeriod: 1000 })
            );
        }

        _testDepositOnly(alice, _liquidVault, depositTestParams.all());

        uint256 partialShares = 1 * _scale;

        // ------------ requestRedeem #1 ------------
        uint256 redeemPeriod1 = 30;

        IMTVTestParamArray redeemParams1 = _split(depositTestParams, 0, 2);
        redeemParams1.set(2, partialShares);

        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams1, redeemPeriod1);

        // ------------ requestRedeem #2 ------------
        uint256 redeemPeriod2 = 50;

        IMTVTestParamArray redeemParams2 = _split(depositTestParams, 2, 4);
        redeemParams2.set(0, depositTestParams.get(2).principal - partialShares);
        redeemParams2.set(2, partialShares);

        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams2, redeemPeriod2);

        // ------------ redeems ------------
        // NB - call the redeem AFTER the multiple requestRedeems.  verify multiple requestRedeems work.

        _testRedeemMultiDeposit(alice, _liquidVault, redeemParams1, redeemPeriod1);

        _testRedeemMultiDeposit(alice, _liquidVault, redeemParams2, redeemPeriod2);
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
