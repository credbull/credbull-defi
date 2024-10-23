// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract LiquidContinuousMultiTokenVaultTest is LiquidContinuousMultiTokenVaultTestBase {
    using TestParamSet for TestParamSet.TestParam[];

    function test__LiquidContinuousMultiTokenVault__RedeemAtTenor() public {
        testVaultAtOffsets(
            alice,
            _liquidVault,
            TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: _liquidVault.TENOR() })
        );
    }

    function test__LiquidContinuousMultiTokenVault__RedeemBeforeTenor() public {
        testVaultAtOffsets(
            bob,
            _liquidVault,
            TestParamSet.TestParam({
                principal: 100 * _scale,
                depositPeriod: 1,
                redeemPeriod: (_liquidVault.TENOR() - 1)
            })
        );
    }

    function test__LiquidContinuousMultiTokenVault__LoadTest() public {
        vm.skip(true); // load test - should only be run during perf testing

        uint256 principal = 100_000 * _scale;

        _loadTestVault(_liquidVault, principal, 1, 1_000); // 1,000 works, 1800 too much for the vm
    }

    function test__LiquidContinuousMultiTokenVault__DepositRedeem() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault; // _createLiquidContinueMultiTokenVault(_vaultParams);

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

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

        // we process deposits immediately - therefore we don't have pending or claimable deposits
        vm.startPrank(alice);
        assertEq(
            0,
            _liquidVault.pendingDepositRequest(testParams.depositPeriod, alice),
            "deposits are processed immediately, not pending"
        );
        assertEq(
            0,
            _liquidVault.claimableDepositRequest(testParams.depositPeriod, alice),
            "deposits are processed immediately, not claimable"
        );
        assertEq(
            0,
            _liquidVault.pendingRedeemRequest(testParams.redeemPeriod, alice),
            "there shouldn't be any pending requestRedeems"
        );
        assertEq(
            0,
            _liquidVault.claimableRedeemRequest(testParams.redeemPeriod, alice),
            "there shouldn't be any claimable redeems"
        );
        vm.stopPrank();

        // ---------------- requestRedeem ----------------
        _warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        // requestRedeem
        vm.prank(alice);
        uint256 requestId = liquidVault.requestRedeem(sharesAmount, alice, alice);
        assertEq(requestId, testParams.redeemPeriod, "requestId should be the redeemPeriod");

        vm.prank(alice);
        assertEq(
            sharesAmount,
            _liquidVault.pendingRedeemRequest(testParams.redeemPeriod, alice),
            "pending request redeem amount not correct"
        );

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
        assertEq(
            sharesAmount,
            _liquidVault.claimableRedeemRequest(testParams.redeemPeriod, alice),
            "claimable redeem amount not correct"
        );

        vm.prank(alice);
        liquidVault.redeem(testParams.principal, alice, alice);

        assertEq(0, liquidVault.balanceOf(alice, testParams.depositPeriod), "user should have no shares remaining");
        assertEq(
            assetStartBalance + expectedYield,
            _asset.balanceOf(alice),
            "user should have received principal + yield back"
        );
    }

    function test__LiquidContinuousMultiTokenVault__WithdrawAssetFromVault() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });
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

    function test__LiquidContinuousMultiTokenVault__RedeemMultiPeriodsAllShares() public {
        uint256 depositPeriods = 5;
        TestParamSet.TestParam[] memory depositTestParams = new TestParamSet.TestParam[](depositPeriods);

        // run in some deposits
        uint256 baseDepositAmount = 100 * _scale;
        for (uint256 i = 0; i < depositPeriods; ++i) {
            depositTestParams[i] = TestParamSet.TestParam({
                principal: (baseDepositAmount * i) + 1 * _scale,
                depositPeriod: i,
                redeemPeriod: 100
            });
        }

        _testDepositOnly(alice, _liquidVault, depositTestParams);

        // split our deposits into two "batches" of redeems
        (TestParamSet.TestParam[] memory redeemParams1, TestParamSet.TestParam[] memory redeemParams2) =
            depositTestParams._splitBefore(3);
        assertEq(3, redeemParams1.length, "array not split 1");
        assertEq(2, redeemParams2.length, "array not split 2");

        // ------------ requestRedeem #1 -----------
        uint256 redeemPeriod1 = 31;
        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams1, 31);

        // ------------ requestRedeem #2 ------------
        uint256 redeemPeriod2 = 41;
        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams2, 41);

        // ------------ redeems ------------
        // NB - call the redeem AFTER the multiple requestRedeems.  verify multiple requestRedeems work.
        _testRedeemAfterRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams1, redeemPeriod1);

        _testRedeemAfterRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams2, redeemPeriod2);
    }

    function test__LiquidContinuousMultiTokenVault__RedeemMultiPeriodsPartialShares() public {
        uint256 depositPeriods = 5;
        TestParamSet.TestParam[] memory depositTestParams = new TestParamSet.TestParam[](depositPeriods);

        // run in some deposits
        uint256 baseDepositAmount = 100 * _scale;
        for (uint256 i = 0; i < depositPeriods; ++i) {
            depositTestParams[i] = TestParamSet.TestParam({
                principal: (baseDepositAmount * i) + 1 * _scale,
                depositPeriod: i,
                redeemPeriod: 1000
            });
        }

        _testDepositOnly(alice, _liquidVault, depositTestParams);

        uint256 partialShares = 1 * _scale;

        // ------------ requestRedeem #1 ------------
        uint256 redeemPeriod1 = 30;
        TestParamSet.TestParam[] memory redeemParams1 = depositTestParams._subset(0, 2);
        redeemParams1[2].principal = partialShares;

        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams1, redeemPeriod1);

        // ------------ requestRedeem #2 ------------
        uint256 redeemPeriod2 = 50;
        TestParamSet.TestParam[] memory redeemParams2 = depositTestParams._subset(2, 4);
        redeemParams2[0].principal = (depositTestParams[2].principal - partialShares);
        redeemParams2[2].principal = partialShares;

        _testRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams2, redeemPeriod2);

        // ------------ redeems ------------
        // NB - call the redeem AFTER the multiple requestRedeems.  verify multiple requestRedeems work.

        _testRedeemAfterRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams1, redeemPeriod1);

        _testRedeemAfterRequestRedeemMultiDeposit(alice, _liquidVault, redeemParams2, redeemPeriod2);
    }

    function test__LiquidContinuousMultiTokenVault__WithdrawAssetNotOwnerReverts() public {
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
    function test__LiquidContinuousMultiTokenVault__50k_Returns() public view {
        uint256 deposit = 50_000 * _scale;

        // verify returns
        uint256 actualYield = _liquidVault.calcYield(deposit, 0, _liquidVault.TENOR());
        assertEq(416_666666, actualYield, "interest not correct for $50k deposit after 30 days");

        // verify principal + returns
        uint256 actualShares = _liquidVault.convertToShares(deposit);
        uint256 actualReturns = _liquidVault.convertToAssetsForDepositPeriod(actualShares, 0, _liquidVault.TENOR());
        assertEq(50_416_666666, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }

    function test__LiquidContinuousMultiTokenVault__ControllerNotSenderReverts() public {
        address randomController = makeAddr("randomController");

        vm.prank(randomController);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__ControllerMismatch.selector,
                randomController,
                alice
            )
        );
        _liquidVault.requestDeposit(1 * _scale, alice, alice);

        vm.prank(randomController);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__ControllerMismatch.selector,
                randomController,
                alice
            )
        );
        _liquidVault.deposit(1 * _scale, alice, alice);
    }

    function test__LiquidContinuousMultiTokenVault__FractionalAssetsGivesZeroShares() public view {
        uint256 fractionalAssets = _scale - 1; // less than the scale (fractional)
        uint256 depositPeriod = 1;

        assertEq(
            0,
            _liquidVault.convertToSharesForDepositPeriod(fractionalAssets, depositPeriod),
            "zero shares for fractional assets"
        );
    }

    function test__LiquidContinuousMultiTokenVault__FractionalSharesGivesZeroAssets() public view {
        uint256 fractionalShares = _scale - 1; // less than the scale (fractional)
        uint256 depositPeriod = 2;
        uint256 redeemPeriod = depositPeriod;

        assertEq(
            0,
            _liquidVault.convertToAssetsForDepositPeriod(fractionalShares, depositPeriod, redeemPeriod),
            "zero assets for fractional shares"
        );
    }

    function test__LiquidContinuousMultiTokenVault__RedeemBeforeDepositPeriodGivesZeroAssets() public view {
        uint256 shares = 100 * _scale;
        uint256 depositPeriod = 3;
        uint256 redeemPeriod = depositPeriod - 1;

        assertEq(
            0,
            _liquidVault.convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod),
            "zero assets when redeemPeriod < depositPeriod"
        );
    }

    function test__LiquidContinuousMultiTokenVault__RedeemMustBeRequestedAmountAndAuthorized() public {
        uint256 redeemPeriod = 10;
        uint256 depositPeriod = 2;

        TestParamSet.TestParam memory testParam = TestParamSet.TestParam({
            principal: 100 * _scale,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });

        // deposit
        uint256 shares = _testDepositOnly(alice, _liquidVault, testParam);

        // request redeem
        _warpToPeriod(_liquidVault, redeemPeriod - _liquidVault.noticePeriod());

        uint256 sharesToRedeem = shares / 2; // redeem say half our shares

        vm.prank(alice);
        _liquidVault.requestRedeem(sharesToRedeem, alice, alice);

        // redeem should fail - requestRedeemAmount != redeemAmount
        _warpToPeriod(_liquidVault, redeemPeriod);

        uint256 invalidRedeemShareAmount = sharesToRedeem - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount.selector,
                invalidRedeemShareAmount,
                sharesToRedeem
            )
        );
        _liquidVault.redeem(invalidRedeemShareAmount, alice, alice);

        // redeem should fail - caller != owner
        address invalidCaller = makeAddr("callerNotAuthorized");
        vm.prank(invalidCaller);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__AuthorizeCallerFailed.selector, invalidCaller, alice
            )
        );
        _liquidVault.redeem(sharesToRedeem, alice, alice);

        // redeem should succeed
        vm.prank(alice);
        uint256 assets = _liquidVault.redeem(sharesToRedeem, alice, alice);
        assertLt(0, assets, "redeem should succeed");
    }
}
