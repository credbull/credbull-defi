// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract LiquidContinuousMultiTokenVaultTest is LiquidContinuousMultiTokenVaultTestBase {
    using TestParamSet for TestParamSet.TestParam[];

    function test__LiquidContinuousMultiTokenVault__SimpleDepositAndRedeemAtTenor() public {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _liquidVerifier._createTestUsers(_alice);
        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] =
            TestParamSet.TestParam({ principal: 250 * _scale, depositPeriod: 0, redeemPeriod: _liquidVault.TENOR() });

        uint256[] memory sharesAtPeriods = _liquidVerifier._verifyDepositOnly(depositUsers, _liquidVault, testParams);
        _liquidVerifier._verifyRedeemOnly(redeemUsers, _liquidVault, testParams, sharesAtPeriods);
    }

    // @dev [Oct 25, 2024] Succeeds with: from=1 and to=600 ; Fails with: from=1 and to=650
    function test__LiquidContinuousMultiTokenVault__LoadTest() public {
        vm.skip(true); // load test - should only be run during perf testing
        TestParamSet.TestParam[] memory loadTestParams = TestParamSet.toLoadSet(100_000 * _scale, 1, 600);

        address carol = makeAddr("carol");
        _transferFromTokenOwner(_asset, carol, 1_000_000_000 * _scale);
        (TestParamSet.TestUsers memory depositUsers1, TestParamSet.TestUsers memory redeemUsers1) =
            _liquidVerifier._createTestUsers(carol);

        // ------------------- deposits w/ redeems per deposit -------------------
        // NB - test all of the deposits BEFORE redeems.  verifies no side-effects from deposits when redeeming.
        uint256[] memory sharesAtPeriods =
            _liquidVerifier._verifyDepositOnly(depositUsers1, _liquidVault, loadTestParams);

        // NB - test all of the redeems AFTER deposits.  verifies no side-effects from deposits when redeeming.
        _liquidVerifier._verifyRedeemOnly(redeemUsers1, _liquidVault, loadTestParams, sharesAtPeriods);
    }

    function test__LiquidContinuousMultiTokenVault__DepositRedeem() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault; // _createLiquidContinueMultiTokenVault(_vaultParams);

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 71 });

        uint256 assetStartBalance = _asset.balanceOf(_alice);

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share

        // ---------------- deposit ----------------
        _liquidVerifier._warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(_alice);
        _asset.approve(address(liquidVault), testParams.principal); // grant the vault allowance
        liquidVault.requestDeposit(testParams.principal, _alice, _alice);
        vm.stopPrank();

        assertEq(
            testParams.principal,
            _asset.balanceOf(address(liquidVault)),
            "vault should have the principal worth of assets"
        );
        assertEq(
            testParams.principal,
            liquidVault.balanceOf(_alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );

        // we process deposits immediately - therefore we don't have pending or claimable deposits
        vm.startPrank(_alice);
        assertEq(
            0,
            _liquidVault.pendingDepositRequest(testParams.depositPeriod, _alice),
            "deposits are processed immediately, not pending"
        );
        assertEq(
            0,
            _liquidVault.claimableDepositRequest(testParams.depositPeriod, _alice),
            "deposits are processed immediately, not claimable"
        );
        assertEq(
            0,
            _liquidVault.pendingRedeemRequest(testParams.redeemPeriod, _alice),
            "there shouldn't be any pending requestRedeems"
        );
        assertEq(
            0,
            _liquidVault.claimableRedeemRequest(testParams.redeemPeriod, _alice),
            "there shouldn't be any claimable redeems"
        );
        vm.stopPrank();

        // ---------------- requestRedeem ----------------
        _liquidVerifier._warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        // requestRedeem
        vm.prank(_alice);
        uint256 requestId = liquidVault.requestRedeem(sharesAmount, _alice, _alice);
        assertEq(requestId, testParams.redeemPeriod, "requestId should be the redeemPeriod");

        vm.prank(_alice);
        assertEq(
            sharesAmount,
            _liquidVault.pendingRedeemRequest(testParams.redeemPeriod, _alice),
            "pending request redeem amount not correct"
        );

        assertEq(
            sharesAmount,
            liquidVault.unlockRequestAmountByDepositPeriod(_alice, testParams.depositPeriod),
            "unlockRequest should be created"
        );

        // ---------------- sell (redeem) ----------------
        uint256 expectedYield = _liquidVerifier._expectedReturns(sharesAmount, liquidVault, testParams);
        assertEq(33_333333, expectedYield, "expected returns incorrect");
        _transferFromTokenOwner(_asset, address(liquidVault), expectedYield); // fund the vault to cover redeem

        _liquidVerifier._warpToPeriod(liquidVault, testParams.redeemPeriod);

        vm.prank(_alice);
        assertEq(
            sharesAmount,
            _liquidVault.claimableRedeemRequest(testParams.redeemPeriod, _alice),
            "claimable redeem amount not correct"
        );

        vm.prank(_alice);
        liquidVault.redeem(testParams.principal, _alice, _alice);

        assertEq(0, liquidVault.balanceOf(_alice, testParams.depositPeriod), "user should have no shares remaining");
        assertEq(
            assetStartBalance + expectedYield,
            _asset.balanceOf(_alice),
            "user should have received principal + yield back"
        );
    }

    function test__LiquidContinuousMultiTokenVault__WithdrawAssetFromVault() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });
        address assetManager = _vaultAuth.assetManager;

        // ---------------- deposit ----------------
        _liquidVerifier._warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(_alice);
        _asset.approve(address(liquidVault), testParams.principal); // grant the vault allowance
        liquidVault.requestDeposit(testParams.principal, _alice, _alice);
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

        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _liquidVerifier._createTestUsers(_alice);

        _liquidVerifier._verifyDepositOnly(depositUsers, _liquidVault, depositTestParams);

        // split our deposits into two "batches" of redeems
        (TestParamSet.TestParam[] memory redeemParams1, TestParamSet.TestParam[] memory redeemParams2) =
            depositTestParams._splitBefore(3);
        assertEq(3, redeemParams1.length, "array not split 1");
        assertEq(2, redeemParams2.length, "array not split 2");

        // ------------ requestRedeem #1 -----------
        uint256 redeemPeriod1 = 31;
        _liquidVerifier._verifyRequestRedeemMultiDeposit(redeemUsers, _liquidVault, redeemParams1, 31);

        // ------------ requestRedeem #2 ------------
        uint256 redeemPeriod2 = 41;
        _liquidVerifier._verifyRequestRedeemMultiDeposit(redeemUsers, _liquidVault, redeemParams2, 41);

        // ------------ redeems ------------
        // NB - call the redeem AFTER the multiple requestRedeems.  verify multiple requestRedeems work.
        _liquidVerifier._verifyRedeemAfterRequestRedeemMultiDeposit(
            redeemUsers, _liquidVault, redeemParams1, redeemPeriod1
        );

        _liquidVerifier._verifyRedeemAfterRequestRedeemMultiDeposit(
            redeemUsers, _liquidVault, redeemParams2, redeemPeriod2
        );
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

        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _liquidVerifier._createTestUsers(_bob);

        _liquidVerifier._verifyDepositOnly(depositUsers, _liquidVault, depositTestParams);

        uint256 partialShares = 1 * _scale;

        // ------------ requestRedeem #1 ------------
        uint256 redeemPeriod1 = 30;
        TestParamSet.TestParam[] memory redeemParams1 = depositTestParams._subset(0, 2);
        redeemParams1[2].principal = partialShares;

        _liquidVerifier._verifyRequestRedeemMultiDeposit(redeemUsers, _liquidVault, redeemParams1, redeemPeriod1);

        // ------------ requestRedeem #2 ------------
        uint256 redeemPeriod2 = 50;
        TestParamSet.TestParam[] memory redeemParams2 = depositTestParams._subset(2, 4);
        redeemParams2[0].principal = (depositTestParams[2].principal - partialShares);
        redeemParams2[2].principal = partialShares;

        _liquidVerifier._verifyRequestRedeemMultiDeposit(redeemUsers, _liquidVault, redeemParams2, redeemPeriod2);

        // ------------ redeems ------------
        // NB - call the redeem AFTER the multiple requestRedeems.  verify multiple requestRedeems work.
        _liquidVerifier._verifyRedeemAfterRequestRedeemMultiDeposit(
            redeemUsers, _liquidVault, redeemParams1, redeemPeriod1
        );

        _liquidVerifier._verifyRedeemAfterRequestRedeemMultiDeposit(
            redeemUsers, _liquidVault, redeemParams2, redeemPeriod2
        );
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

        uint256 tenorPlusNoticePeriod = _liquidVault.TENOR() + _liquidVault.noticePeriod();

        // verify returns
        uint256 actualYield = _liquidVault.calcYield(deposit, 0, tenorPlusNoticePeriod);
        assertEq(416_666666, actualYield, "interest not correct for $50k deposit after 30 days");

        // verify principal + returns
        uint256 actualShares = _liquidVault.convertToShares(deposit);
        uint256 actualReturns = _liquidVault.convertToAssetsForDepositPeriod(actualShares, 0, tenorPlusNoticePeriod);
        assertEq(50_416_666666, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }

    function test__LiquidContinuousMultiTokenVault__TotalAssetsAndConvertToAssets() public {
        uint256 depositPeriod1 = 5;
        uint256 depositPeriod2 = depositPeriod1 + 1;
        uint256 redeemPeriod = 10;
        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](2);
        testParams[0] = TestParamSet.TestParam({
            principal: 50 * _scale,
            depositPeriod: depositPeriod1,
            redeemPeriod: redeemPeriod
        });
        testParams[1] = TestParamSet.TestParam({
            principal: 80 * _scale,
            depositPeriod: depositPeriod2,
            redeemPeriod: redeemPeriod
        });

        uint256[] memory shares =
            _liquidVerifier._verifyDepositOnly(TestParamSet.toSingletonUsers(_alice), _liquidVault, testParams);
        uint256 totalShares = shares[0] + shares[1];

        // -------------- deposit period1  --------------
        _liquidVerifier._warpToPeriod(_liquidVault, depositPeriod1);

        uint256 assetsAtDepositPeriod1 =
            _liquidVault.convertToAssetsForDepositPeriod(shares[0], testParams[0].depositPeriod, depositPeriod1);

        vm.prank(_alice);
        assertEq(assetsAtDepositPeriod1, _liquidVault.convertToAssets(shares[0]), "assets wrong at deposit period 1");

        // -------------- deposit period2 --------------
        _liquidVerifier._warpToPeriod(_liquidVault, depositPeriod2);

        uint256 assetsAtDepositPeriod2 =
            _liquidVault.convertToAssetsForDepositPeriod(shares[1], testParams[1].depositPeriod, depositPeriod2);

        vm.prank(_alice);
        assertEq(assetsAtDepositPeriod2, _liquidVault.convertToAssets(shares[1]), "assets wrong at deposit period 2");
        assertEq(
            assetsAtDepositPeriod1 + assetsAtDepositPeriod2,
            _liquidVault.totalAssets(),
            "totalAssets wrong at deposit period 2"
        );

        // -------------- requestRedeem period --------------
        uint256 requestRedeemPeriod = redeemPeriod - _liquidVault.noticePeriod();
        _liquidVerifier._warpToPeriod(_liquidVault, requestRedeemPeriod);

        uint256 assetsAtRequestRedeemPeriod = _liquidVault.convertToAssetsForDepositPeriod(
            shares[0], testParams[0].depositPeriod, requestRedeemPeriod
        ) + _liquidVault.convertToAssetsForDepositPeriod(shares[1], testParams[1].depositPeriod, requestRedeemPeriod);

        vm.prank(_alice);
        assertEq(
            assetsAtRequestRedeemPeriod,
            _liquidVault.convertToAssets(totalShares),
            "assets wrong at requestRedeem period"
        );

        assertEq(assetsAtRequestRedeemPeriod, _liquidVault.totalAssets(), "totalAssets wrong at requestRedeem period");
        assertEq(
            assetsAtRequestRedeemPeriod,
            _liquidVault.totalAssets(_alice),
            "totalAssets(user) wrong at requestRedeem period"
        );
        assertEq(0, _liquidVault.totalAssets(_bob), "totalAssets(user) wrong at requestRedeem period");

        // -------------- redeem period --------------
        _liquidVerifier._warpToPeriod(_liquidVault, redeemPeriod);

        uint256 assetsAtRedeemPeriod = _liquidVault.convertToAssetsForDepositPeriod(
            shares[0], testParams[0].depositPeriod, redeemPeriod
        ) + _liquidVault.convertToAssetsForDepositPeriod(shares[1], testParams[1].depositPeriod, redeemPeriod);

        vm.prank(_alice);
        assertEq(assetsAtRedeemPeriod, _liquidVault.convertToAssets(totalShares), "assets wrong at redeem period");

        assertEq(assetsAtRedeemPeriod, _liquidVault.totalAssets(), "totalAssets wrong at redeem period");
        assertEq(assetsAtRedeemPeriod, _liquidVault.totalAssets(_alice), "totalAssets(_alice) wrong at redeem period");
        assertEq(0, _liquidVault.totalAssets(_bob), "totalAssets(_bob) wrong at redeem period");
    }

    function test__LiquidContinuousMultiTokenVault__DepositCallerValidation() public {
        address randomController = makeAddr("randomController");

        // ---------------- request deposit ----------------
        vm.prank(_bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__UnAuthorized.selector, _bob, _alice
            )
        );
        _liquidVault.requestDeposit(1 * _scale, _bob, _alice);

        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__ControllerNotSender.selector,
                _alice,
                randomController
            )
        );
        _liquidVault.requestDeposit(1 * _scale, randomController, _alice);

        // ---------------- deposit ----------------

        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__ControllerNotSender.selector,
                _alice,
                randomController
            )
        );
        _liquidVault.deposit(1 * _scale, _alice, randomController);
    }

    function test__LiquidContinuousMultiTokenVault__RedeemCallerValidation() public {
        address randomController = makeAddr("randomController");

        // ---------------- request redeem ----------------
        vm.prank(_bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__UnAuthorized.selector, _bob, _alice
            )
        );
        _liquidVault.requestRedeem(1 * _scale, _bob, _alice);

        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__ControllerNotSender.selector,
                _alice,
                randomController
            )
        );
        _liquidVault.requestRedeem(1 * _scale, randomController, _alice);

        // ---------------- redeem ----------------

        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__ControllerNotSender.selector,
                _alice,
                randomController
            )
        );
        _liquidVault.redeem(1 * _scale, makeAddr("receiver"), randomController);
    }

    function test__LiquidContinuousMultiTokenVault__FractionalAssetsGivesZeroShares() public view {
        uint256 fractionalAssets = 9; // 9 wei - tiny amount
        uint256 depositPeriod = 1;

        assertEq(
            0,
            _liquidVault.convertToSharesForDepositPeriod(fractionalAssets, depositPeriod),
            "zero shares for fractional assets"
        );
    }

    function test__LiquidContinuousMultiTokenVault__FractionalSharesGivesZeroAssets() public view {
        uint256 fractionalShares = 9; // 9 wei - tiny amount
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
        uint256 shares =
            _liquidVerifier._verifyDepositOnly(TestParamSet.toSingletonUsers(_alice), _liquidVault, testParam);

        // request redeem
        _liquidVerifier._warpToPeriod(_liquidVault, redeemPeriod - _liquidVault.noticePeriod());

        uint256 sharesToRedeem = shares / 2; // redeem say half our shares

        vm.prank(_alice);
        _liquidVault.requestRedeem(sharesToRedeem, _alice, _alice);

        // redeem should fail - requestRedeemAmount != redeemAmount
        _liquidVerifier._warpToPeriod(_liquidVault, redeemPeriod);

        uint256 invalidRedeemShareAmount = sharesToRedeem - 1;

        vm.prank(_alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount.selector,
                invalidRedeemShareAmount,
                sharesToRedeem
            )
        );
        _liquidVault.redeem(invalidRedeemShareAmount, _alice, _alice);

        // redeem should fail - caller doesn't have any tokens to redeem
        address invalidCaller = makeAddr("randomCaller");
        vm.prank(invalidCaller);
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount.selector,
                sharesToRedeem,
                0
            )
        );
        _liquidVault.redeem(sharesToRedeem, _alice, invalidCaller);

        // redeem should succeed
        address receiver = makeAddr("receiver");
        vm.prank(_alice);
        uint256 assets = _liquidVault.redeem(sharesToRedeem, receiver, _alice);
        assertEq(assets, _asset.balanceOf(receiver), "redeem should succeed");
    }

    function test__LiquidContinuousMultiTokenVault__RedeemFractional() public {
        uint256 redeemPeriod = 10;
        uint256 depositPeriod = 2;

        uint256 principalIntegerPart = 5 * _scale; // e.g. 5 ETH
        uint256 principalDecimalPart = 10; // e.g. 10 wei

        TestParamSet.TestParam memory testParam = TestParamSet.TestParam({
            principal: principalIntegerPart + principalDecimalPart,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });

        TestParamSet.TestUsers memory aliceTestUsers = TestParamSet.toSingletonUsers(_alice);

        // deposit
        uint256 shares = _liquidVerifier._verifyDepositOnly(aliceTestUsers, _liquidVault, testParam);

        assertEq(shares, testParam.principal, "shares should be 1:1 with principal"); // liquid vault should be 1:1

        // ----------------- redeem principal first -----------------
        TestParamSet.TestParam memory integerTestParam = TestParamSet.TestParam({
            principal: principalIntegerPart,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });

        uint256 assetIntegerPart =
            _liquidVerifier._verifyRedeemOnly(aliceTestUsers, _liquidVault, integerTestParam, principalIntegerPart);
        assertLe(
            principalIntegerPart, assetIntegerPart, "principal + returns should be at least principal integer amount"
        );

        // ----------------- redeem decimal second -----------------
        TestParamSet.TestParam memory decimalTestParam = TestParamSet.TestParam({
            principal: principalDecimalPart,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });

        uint256 assetDecimalPart =
            _liquidVerifier._verifyRedeemOnly(aliceTestUsers, _liquidVault, decimalTestParam, principalDecimalPart);
        assertLe(
            principalDecimalPart, assetDecimalPart, "principal + returns should be at least principal decimal amount"
        );
    }

    // ================== F-2024-6700 ==================
    /**
     * Scenario
     * 1. Alice deposits assets at the deposit period.
     * 2. Alice requests redeem to withdraw assets from the vault.
     * 3. Alice wants to cancel redeem request before the redeem period.
     */
    function test__LiquidContinuousMultiTokenVault__CancelUnlockRequest__BeforeRedeemPeriod() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

        uint256 sharesAmount = testParams.principal;

        _liquidVerifier._warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(_alice);
        _asset.approve(address(liquidVault), testParams.principal);
        liquidVault.requestDeposit(testParams.principal, _alice, _alice);
        vm.stopPrank();

        _liquidVerifier._warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        // Alice requests redeem for sharesAmount
        vm.prank(_alice);
        uint256 requestId = liquidVault.requestRedeem(sharesAmount, _alice, _alice);

        assertEq(requestId, testParams.redeemPeriod, "requestId should be the redeemPeriod");

        // When _alice calls unlock before redeem period, it will revert
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeCurrentPeriod.selector,
                _alice,
                _alice,
                liquidVault.currentPeriod(),
                testParams.redeemPeriod
            )
        );
        vm.prank(_alice);
        liquidVault.unlock(_alice, requestId);

        // Alice cancels his redeem request and it works even before the redeem period.
        vm.prank(_alice);
        liquidVault.cancelRequestUnlock(_alice, requestId);

        assertEq(
            0, _liquidVault.pendingRedeemRequest(requestId, _alice), "there shouldn't be any pending requestRedeems"
        );

        assertEq(0, _liquidVault.claimableRedeemRequest(requestId, _alice), "there shouldn't be any claimable redeems");

        // Alice calls this function again, but nothing happens.
        vm.prank(_alice);
        liquidVault.cancelRequestUnlock(_alice, requestId);
    }

    /**
     * Scenario
     * 1. Alice deposits assets at the deposit period.
     * 2. Alice requests to redeem for [sharesAmount]
     * 3. Alice wants to decrease his redeem request amount to [sharesAmount / 2] before redeem Period
     */
    function test__LiquidContinuousMultiTokenVault__ModifyUnlockRequest__BeforeRedeemPeriod() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

        uint256 sharesAmount = testParams.principal;

        _liquidVerifier._warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(_alice);
        _asset.approve(address(liquidVault), testParams.principal);
        liquidVault.requestDeposit(testParams.principal, _alice, _alice);
        vm.stopPrank();

        _liquidVerifier._warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        vm.prank(_alice);
        uint256 requestId = liquidVault.requestRedeem(sharesAmount, _alice, _alice);

        // Alice cancels his redeem request first
        vm.startPrank(_alice);
        liquidVault.cancelRequestUnlock(_alice, requestId);

        // Alice submits a redeem request again with the amount = [sharesAmount / 2].
        requestId = liquidVault.requestRedeem(sharesAmount / 2, _alice, _alice);
        vm.stopPrank();

        vm.prank(_alice);
        assertEq(
            sharesAmount / 2,
            _liquidVault.pendingRedeemRequest(requestId, _alice),
            "pending request redeem amount not correct"
        );

        assertEq(
            sharesAmount / 2,
            liquidVault.unlockRequestAmountByDepositPeriod(_alice, testParams.depositPeriod),
            "unlockRequest should be created"
        );
    }

    /**
     * Scenario
     * 1. Alice deposits assets at the deposit period.
     * 2. Alice requests to redeem for [sharesAmount_1_Alice]
     * 3. Alice transfers [sharesAmount_1_David] shares to David
     * 4. David requests reedeem for sharesAmount_1_David
     * 5. Alice makes another request redeems for [sharesAmount_2_Alice]
     * 6. Alice transfers another amount[sharesAmount_2_David] of shares to David
     * 7. David makes another redeem request for [sharesAmount_2_David]
     * 8. Alice cancels his redeem request (because redeem will fail)
     * 9. Alice makes new redeem request at redeem period
     * 10.David redeems his shares which already requested at redeem period
     */
    function test__LiquidContinuousMultiTokenVault__ModifyUnlockRequest__Sdsed() public {
        LiquidContinuousMultiTokenVault liquidVault = _liquidVault;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

        uint256 sharesAmount_1_Alice = testParams.principal / 2;

        _liquidVerifier._warpToPeriod(liquidVault, testParams.depositPeriod);

        vm.startPrank(_alice);
        _asset.approve(address(liquidVault), testParams.principal);
        liquidVault.requestDeposit(testParams.principal, _alice, _alice);
        vm.stopPrank();

        _liquidVerifier._warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        // Alice requests redeem for sharesAmount_1_Alice
        vm.prank(_alice);
        uint256 requestId = liquidVault.requestRedeem(sharesAmount_1_Alice, _alice, _alice);

        address david = makeAddr("david");

        uint256 sharesAmount_1_David = sharesAmount_1_Alice / 2;

        // Alice transfers [sharesAmount_1_David] shares to David
        vm.prank(_alice);
        liquidVault.safeTransferFrom(_alice, david, testParams.depositPeriod, sharesAmount_1_David, "");

        assertEq(sharesAmount_1_David, liquidVault.balanceOf(david, testParams.depositPeriod));
        assertEq(
            testParams.principal - sharesAmount_1_David, liquidVault.lockedAmount(_alice, testParams.depositPeriod)
        );

        // David requests reedeem for sharesAmount_1_David
        vm.startPrank(david);
        liquidVault.requestRedeem(sharesAmount_1_David, david, david);

        assertEq(
            sharesAmount_1_David,
            _liquidVault.pendingRedeemRequest(requestId, david),
            "david pending request redeem amount not correct"
        );
        vm.stopPrank();

        // Alice makes another request redeems
        uint256 sharesAmount_2_Alice = testParams.principal - sharesAmount_1_Alice - sharesAmount_1_David;

        vm.startPrank(_alice);
        liquidVault.requestRedeem(sharesAmount_2_Alice, _alice, _alice);

        assertEq(
            sharesAmount_1_Alice + sharesAmount_2_Alice,
            _liquidVault.pendingRedeemRequest(requestId, _alice),
            "_alice pending request redeem amount not correct"
        );
        vm.stopPrank();

        // Alice transfers another amount of shares to David
        // amount = (sharesAmount_1_Alice + sharesAmount_2_Alice) / 2

        uint256 sharesAmount_2_David = (sharesAmount_1_Alice + sharesAmount_2_Alice) / 2;
        vm.prank(_alice);
        liquidVault.safeTransferFrom(_alice, david, testParams.depositPeriod, sharesAmount_2_David, "");

        assertEq(sharesAmount_1_David + sharesAmount_2_David, liquidVault.balanceOf(david, testParams.depositPeriod));

        uint256 remainingShare_Alice = testParams.principal - sharesAmount_1_David - sharesAmount_2_David;
        assertEq(remainingShare_Alice, liquidVault.balanceOf(_alice, testParams.depositPeriod));
        assertTrue(
            remainingShare_Alice < liquidVault.unlockRequestAmountByDepositPeriod(_alice, testParams.depositPeriod),
            "Alice requested unlock amount should be bigger than locked amount"
        );

        // David makes another redeem request
        vm.startPrank(david);
        liquidVault.requestRedeem(sharesAmount_2_David, david, david);

        assertEq(
            sharesAmount_1_David + sharesAmount_2_David,
            _liquidVault.pendingRedeemRequest(requestId, david),
            "david pending request redeem amount not correct"
        );
        vm.stopPrank();

        _liquidVerifier._warpToPeriod(liquidVault, testParams.redeemPeriod);

        // We expect revert in Alice's redeem because shares and ruquest unlocked amount for Alice are different
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount.selector,
                remainingShare_Alice,
                liquidVault.unlockRequestAmountByDepositPeriod(_alice, testParams.depositPeriod)
            )
        );
        vm.prank(_alice);
        liquidVault.redeem(remainingShare_Alice, _alice, _alice);

        // Alice cancels his redeem request
        // Alice can use either cancelRedeemRequest or unlock
        vm.prank(_alice);
        liquidVault.cancelRequestUnlock(_alice, requestId);
        // Alice makes another unlock request
        vm.prank(_alice);
        liquidVault.requestRedeem(remainingShare_Alice, _alice, _alice);

        // David redeems his shares
        vm.startPrank(david);
        liquidVault.redeem(sharesAmount_1_David + sharesAmount_2_David, david, david);

        assertEq(
            0, _liquidVault.pendingRedeemRequest(requestId, david), "david pending request redeem amount should be zero"
        );

        assertEq(0, liquidVault.balanceOf(david, testParams.depositPeriod), "david should have no shares remaining");
        vm.stopPrank();
    }

    // Scenario: User requests redemption before the cutoff time on the same day as deposit
    // Given the Redemption Request cutoff time is 2:59:59pm
    // And the Redemption Settlement cutoff time is 2:59:59pm the next day
    // And Alice deposits 100 USDC on Day 1 at 2:59:58pm
    // When Alice requests full redemption on Day 1 at 2:59:58pm
    // Then Alice's redemption should be settled on Day 2 at 2:59:59pm
    // And Alice should not receive any yield just the pincipal (100 USDC)
    function test__LiquidContinuousMultiTokenVault__DepositAndRedeemAtCutOffs() public {
        uint256 principal = 10 * _scale;

        deal(address(_asset), address(_liquidVault), 100e6);

        // ----------------- deposit ------------
        uint256 depositAtCutoff = _liquidVault._vaultStartTimestamp() + 1 days - 1 minutes;
        vm.warp(depositAtCutoff); // set the time very close to the cut-off

        uint256 depositPeriod = _liquidVault.currentPeriod();
        vm.startPrank(_alice);
        _asset.approve(address(_liquidVault), principal);
        uint256 shares = _liquidVault.deposit(principal, _alice);
        vm.stopPrank();

        // ----------------- requestRedeem ------------
        // request redeem on the deposit day
        vm.prank(_alice);
        uint256 redeemPeriod = _liquidVault.requestRedeem(shares, _alice, _alice);

        // ----------------- redeem  ------------
        vm.warp(depositAtCutoff + 2 minutes); // warp to the next day
        assertEq(redeemPeriod, _liquidVault.currentPeriod(), "didn't tick over a day");

        uint256 assetPreview = _liquidVault.previewRedeemForDepositPeriod(shares, depositPeriod, redeemPeriod);
        assertEq(principal, assetPreview, "assets should be the same as principal");

        vm.prank(_alice);
        uint256 assets = _liquidVault.redeem(shares, _alice, _alice);
        assertEq(principal, assets, "assets should be the same as principal");
    }

    function test__LiquidContinuousMultiTokenVault__CalcYieldEdgeCases() public view {
        uint256 principal = 1_000_000_000 * _scale;
        uint256 zeroPeriod = 0;
        uint256 hundredPeriod = 100;
        uint256 noticePeriod = _liquidVault.noticePeriod();

        // check scenarios with zero returns
        assertEq(
            0,
            _liquidVault.calcYield(principal, zeroPeriod, zeroPeriod),
            "no returns when redeeming at deposit period - deposit at 0"
        );
        assertEq(
            0,
            _liquidVault.calcYield(principal, hundredPeriod, hundredPeriod),
            "no returns when redeeming at deposit period - deposit at 100"
        );

        assertEq(
            0,
            _liquidVault.calcYield(principal, zeroPeriod, zeroPeriod + noticePeriod),
            "no returns when redeeming at notice period - deposit at 0"
        );
        assertEq(
            0,
            _liquidVault.calcYield(principal, hundredPeriod, hundredPeriod + noticePeriod),
            "no returns when redeeming at notice period - deposit at 100"
        );

        assertEq(
            0,
            _liquidVault.calcYield(principal, 1, zeroPeriod),
            "zero yield redeem less than deposit period - redeem at 0"
        );
        assertEq(
            0,
            _liquidVault.calcYield(principal, hundredPeriod, hundredPeriod - 1),
            "zero yield redeem less than deposit period - redeem at 99"
        );

        // check scenarios with returns
        assertLt(
            0,
            _liquidVault.calcYield(principal, zeroPeriod, zeroPeriod + noticePeriod + 1),
            "redeem > notice period should have yield"
        );
        assertLt(
            0,
            _liquidVault.calcYield(principal, hundredPeriod, hundredPeriod + noticePeriod + 1),
            "redeem > notice period should have yield"
        );
    }
}
