// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IMultiTokenVaultTestBase } from "@test/test/token/ERC1155/IMultiTokenVaultTestBase.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";
import { MultiTokenVaultDailyPeriods } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriods.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IVaultTestSuite } from "@test/src/token/ERC4626/IVaultTestSuite.t.sol";
import { IVaultTestVerifier } from "@test/test/token/ERC4626/IVaultTestVerifier.t.sol";
import { IVaultTestBase } from "@test/test/token/ERC4626/IVaultTestBase.t.sol";

contract MultiTokenVaultTest is IMultiTokenVaultTestBase, IVaultTestSuite {
    using TestParamSet for TestParamSet.TestParam[];

    uint256 public constant TEST_ASSET_TO_SHARE_RATIO = 3;

    IMultiTokenVault private _multiTokenVault;

    function setUp() public virtual override {
        super.setUp();

        _multiTokenVault = _createMultiTokenVault(_asset, 3, 10);
    }

    function test__MultiTokenVaultTest__RedeemBeforeDepositPeriodReverts() public {
        IMultiTokenVault vault = _createMultiTokenVault(_asset, 1, 10);

        TestParamSet.TestParam memory testParam =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 2, redeemPeriod: 1 });

        // deposit period > redeem period should fail
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__RedeemBeforeDeposit.selector,
                _alice,
                testParam.depositPeriod,
                testParam.redeemPeriod
            )
        );
        vault.redeemForDepositPeriod(1, _alice, _alice, testParam.depositPeriod, testParam.redeemPeriod);
    }

    function test__MultiTokenVaultTest__CurrentBeforeRedeemPeriodReverts() public {
        IMultiTokenVault vault = _createMultiTokenVault(_asset, 1, 10);

        TestParamSet.TestParam memory testParam =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: 3 });

        uint256 currentPeriod = testParam.redeemPeriod - 1;

        _warpToPeriod(vault, currentPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__RedeemTimePeriodNotSupported.selector,
                _alice,
                currentPeriod,
                testParam.redeemPeriod
            )
        );
        vault.redeemForDepositPeriod(1, _alice, _alice, testParam.depositPeriod, testParam.redeemPeriod);
    }

    function test__MultiTokenVaultTest__RedeemOverMaxSharesReverts() public {
        IMultiTokenVault vault = _createMultiTokenVault(_asset, 1, 10);

        TestParamSet.TestParam memory testParam =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: 3 });

        uint256 sharesToRedeem = 1;

        _warpToPeriod(vault, testParam.redeemPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__ExceededMaxRedeem.selector,
                _alice,
                testParam.depositPeriod,
                sharesToRedeem,
                0
            )
        );
        vault.redeemForDepositPeriod(sharesToRedeem, _alice, _alice, testParam.depositPeriod, testParam.redeemPeriod);
    }

    function test__LiquidContinuousMultiTokenVaultUtil__RedeemWithAllowance() public {
        uint256 assetToSharesRatio = 2;

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: 10 });

        vm.prank(_alice);
        _asset.approve(address(vault), testParams.principal); // grant vault allowance on alice's principal
        _transferFromTokenOwner(_asset, address(vault), testParams.principal); // transfer funds to cover redeem

        vm.prank(_alice);
        uint256 shares = vault.deposit(testParams.principal, _alice);

        // ------------ redeem - without allowance ------------
        _warpToPeriod(vault, testParams.redeemPeriod);

        address allowanceAccount = makeAddr("allowanceAccount");

        // should fail, no allowance given yet
        vm.prank(allowanceAccount);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__CallerMissingApprovalForAll.selector, allowanceAccount, _alice
            )
        );
        vault.redeemForDepositPeriod(shares, _alice, _alice, testParams.depositPeriod, testParams.redeemPeriod);

        // ------------ redeem - with allowance ------------
        vm.prank(_alice);
        vault.setApprovalForAll(allowanceAccount, true); // grant allowance

        // should succeed - allowance granted
        address receiverAccount = makeAddr("receiver");
        vm.prank(allowanceAccount);
        uint256 assets = vault.redeemForDepositPeriod(
            shares, receiverAccount, _alice, testParams.depositPeriod, testParams.redeemPeriod
        );

        assertEq(assets, _asset.balanceOf(receiverAccount), "receiver did not receive assets");
    }

    function test__MultiTokenVaultTest__BatchFunctions() public {
        uint256 assetToSharesRatio = 2;
        uint256 redeemPeriod = 2001;

        TestParamSet.TestParam[] memory _batchTestParams = new TestParamSet.TestParam[](3);
        TestParamSet.TestParam[] memory _batchTestParamsToRevert = new TestParamSet.TestParam[](2);

        _batchTestParams[0] =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: redeemPeriod });
        _batchTestParams[1] =
            TestParamSet.TestParam({ principal: 2002 * _scale, depositPeriod: 202, redeemPeriod: redeemPeriod });
        _batchTestParams[2] =
            TestParamSet.TestParam({ principal: 3003 * _scale, depositPeriod: 303, redeemPeriod: redeemPeriod });

        _batchTestParamsToRevert[0] =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: redeemPeriod });
        _batchTestParamsToRevert[1] =
            TestParamSet.TestParam({ principal: 2002 * _scale, depositPeriod: 202, redeemPeriod: redeemPeriod });

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        uint256[] memory shares = _testDepositOnly(testUsers, vault, _batchTestParams);
        uint256[] memory depositPeriods = _batchTestParams.depositPeriods();
        uint256[] memory depositPeriodsToRevert = _batchTestParamsToRevert.depositPeriods();

        // ------------------------ batch convert to assets ------------------------
        uint256[] memory assets = vault.convertToAssetsForDepositPeriodBatch(shares, depositPeriods, redeemPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__InvalidArrayLength.selector,
                depositPeriodsToRevert.length,
                shares.length
            )
        );
        vault.convertToAssetsForDepositPeriodBatch(shares, depositPeriodsToRevert, redeemPeriod);

        assertEq(3, assets.length, "assets are wrong length");
        assertEq(
            assets[0],
            vault.convertToAssetsForDepositPeriod(shares[0], depositPeriods[0], redeemPeriod),
            "asset mismatch period 0"
        );
        assertEq(
            assets[1],
            vault.convertToAssetsForDepositPeriod(shares[1], depositPeriods[1], redeemPeriod),
            "asset mismatch period 1"
        );
        assertEq(
            assets[2],
            vault.convertToAssetsForDepositPeriod(shares[2], depositPeriods[2], redeemPeriod),
            "asset mismatch period 2"
        );

        // ------------------------ batch approvalForAll safeBatchTransferFrom balance ------------------------
        uint256[] memory aliceBalances = _testBalanceOfBatch(_alice, vault, _batchTestParams, assetToSharesRatio);

        // have alice approve bob for all
        vm.prank(_alice);
        vault.setApprovalForAll(_bob, true);

        // now bob can transfer on behalf of alice to charlie
        vm.prank(_bob);
        vault.safeBatchTransferFrom(_alice, _charlie, depositPeriods, aliceBalances, "");

        _testBalanceOfBatch(_charlie, vault, _batchTestParams, assetToSharesRatio); // verify bob
    }

    function test__MultiTokenVaultTest__ZeroOrOneAssetsShouldGiveZeroShares() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory zeroPrincipal =
            TestParamSet.TestParam({ principal: 0, depositPeriod: 10, redeemPeriod: 21 });
        TestParamSet.TestParam memory onePrincipal =
            TestParamSet.TestParam({ principal: 1, depositPeriod: 10, redeemPeriod: 21 });

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        address vaultAddress = address(vault);

        vm.startPrank(_alice);
        _asset.approve(vaultAddress, onePrincipal.principal);

        // ------------- test for deposit of 0 -------------
        vm.startPrank(_alice);
        uint256 sharesFromZeroPrincipal = vault.deposit(zeroPrincipal.principal, _alice);
        vm.stopPrank();

        assertEq(zeroPrincipal.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, sharesFromZeroPrincipal, "deposit of zero assets should give zero shares");

        // ------------- test for deposit of 1  -------------
        vm.startPrank(_alice);
        uint256 sharesFromOnePrincipal = vault.deposit(onePrincipal.principal, _alice);
        vm.stopPrank();

        // 1 asset converts to 0 shares with any assetToShare ratio > 0.  e.g.: 1 asset / 2 = 0 shares rounded down.
        assertEq(onePrincipal.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, sharesFromOnePrincipal, "deposit of fractional assets should give zero shares");
    }

    function test__MultiTokenVaultTest__SafeTransferFrom() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: 10 });

        // Step 1: Create and set up the vault
        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        // Step 2: Deposit some assets for _alice to receive shares
        vm.startPrank(_alice);
        _asset.approve(address(vault), testParams.principal);
        uint256 shares = vault.deposit(testParams.principal, _alice);
        vm.stopPrank();

        // Verify _alice has received the shares
        assertEq(
            vault.balanceOf(_alice, testParams.depositPeriod), shares, "_alice should have the shares after deposit"
        );

        // Step 3: Perform the safe transfer from _alice to _bob
        vm.startPrank(_alice);
        vault.safeTransferFrom(_alice, _bob, testParams.depositPeriod, shares, "");
        vm.stopPrank();

        // Step 4: Verify the transfer was successful
        assertEq(vault.balanceOf(_alice, testParams.depositPeriod), 0, "_alice should have no shares after transfer");
        assertEq(vault.balanceOf(_bob, testParams.depositPeriod), shares, "_bob should have the transferred shares");
    }

    function test__MultiTokenVaultTest__ConvertToSharesForDepositPeriod() public {
        // Assuming the asset to shares ratio is set to a fixed value for testing.
        uint256 assetToSharesRatio = 2;
        uint256 depositPeriod = 1;

        // Step 1: Create and initialize the vault with a dummy asset
        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        // Typical Case: Convert a positive asset amount to shares
        uint256 assets = 500 * _scale;
        uint256 expectedShares = assets / assetToSharesRatio;
        uint256 shares = vault.convertToSharesForDepositPeriod(assets, depositPeriod);
        assertEq(shares, expectedShares, "Conversion to shares did not match expected value");

        // Edge Case: Convert zero assets to shares
        assets = 0;
        expectedShares = 0;
        shares = vault.convertToSharesForDepositPeriod(assets, depositPeriod);
        assertEq(shares, expectedShares, "Conversion of zero assets to shares failed");

        // Edge Case: Convert maximum assets to shares
        assets = type(uint256).max;
        expectedShares = assets / assetToSharesRatio;
        shares = vault.convertToSharesForDepositPeriod(assets, depositPeriod);
        assertEq(shares, expectedShares, "Conversion of max assets to shares failed");
    }

    function test__MultiTokenVaultTest__ConvertToAssetsForDepositPeriod() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 0, redeemPeriod: 30 });

        // Step 1: Create and initialize the vault with a dummy asset
        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        // Typical Case: Convert a positive share amount to assets
        uint256 shares = testParams.principal / assetToSharesRatio;
        uint256 expectedAssets = shares * assetToSharesRatio + _expectedReturns(shares, vault, testParams);
        uint256 assets =
            vault.convertToAssetsForDepositPeriod(shares, testParams.depositPeriod, testParams.redeemPeriod);
        assertEq(assets, expectedAssets, "Conversion to assets did not match expected value");

        // Edge Case: Convert zero shares to assets
        shares = 0;
        expectedAssets = 0;
        assets = vault.convertToAssetsForDepositPeriod(shares, testParams.depositPeriod, testParams.redeemPeriod);
        assertEq(assets, expectedAssets, "Conversion of zero shares to assets failed");

        // Edge Case: Convert maximum shares to assets
        testParams =
            TestParamSet.TestParam({ principal: type(uint128).max * _scale, depositPeriod: 0, redeemPeriod: 30 });
        shares = testParams.principal / assetToSharesRatio;
        expectedAssets = shares * assetToSharesRatio + _expectedReturns(shares, vault, testParams);
        assets = vault.convertToAssetsForDepositPeriod(shares, testParams.depositPeriod, testParams.redeemPeriod);
        assertEq(assets, expectedAssets, "Conversion of max shares to assets failed");
    }

    function test__MultiTokenVaultTest__PreviewDeposit() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 0, redeemPeriod: 30 });

        uint256 expectedShares = testParams.principal / assetToSharesRatio;

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        uint256 shares = vault.previewDeposit(testParams.principal);
        assertEq(shares, expectedShares, "Preview deposit conversion did not match expected value");
    }

    function test__MultiTokenVaultTest__PreviewRedeemForDepositPeriod() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 0, redeemPeriod: 30 });

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        uint256 shares = testParams.principal / assetToSharesRatio;
        uint256 expectedAssets = shares * assetToSharesRatio + _expectedReturns(shares, vault, testParams);

        uint256 assets = vault.previewRedeemForDepositPeriod(shares, testParams.depositPeriod);
        assertEq(assets, expectedAssets, "Preview redeem conversion did not match expected value");
    }

    function test__MultiTokenVaultTest__IsApprovedForAll() public {
        address operator = makeAddr("operator");
        uint256 assetToSharesRatio = 2;

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        // Set approval
        vm.prank(_alice);
        vault.setApprovalForAll(operator, true);

        // Check if the operator is approved
        bool isApproved = vault.isApprovedForAll(_alice, operator);
        assertEq(isApproved, true, "Operator should be approved");

        // Revoke approval and check
        vm.prank(_alice);
        vault.setApprovalForAll(operator, false);
        isApproved = vault.isApprovedForAll(_alice, operator);
        assertEq(isApproved, false, "Operator should not be approved");
    }

    function test__MultiTokenVaultTest__MaxDeposit() public {
        uint256 assetToSharesRatio = 2;

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        uint256 maxDepositValue = vault.maxDeposit(_alice);
        assertEq(maxDepositValue, type(uint256).max, "Max deposit should be uint256 max");
    }

    function test__MultiTokenVaultTest__MaxRedeemAtPeriod() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 0, redeemPeriod: 30 });

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        // Alice deposits assets and receives shares
        vm.startPrank(_alice);
        _asset.approve(address(vault), testParams.principal);
        uint256 shares = vault.deposit(testParams.principal, _alice);
        vm.stopPrank();

        // Check max redeemable shares for the deposit period
        uint256 maxShares = vault.maxRedeemAtPeriod(_alice, testParams.depositPeriod); // Assuming deposit period = 1
        assertEq(maxShares, shares, "Max redeemable shares did not match the deposited shares");
    }

    function _testBalanceOfBatch(
        address account,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory testParams,
        uint256 assetToSharesRatio
    ) internal view returns (uint256[] memory balances_) {
        address[] memory accounts = testParams.accountArray(account);
        uint256[] memory balances = vault.balanceOfBatch(accounts, testParams.depositPeriods());
        assertEq(3, balances.length, "balances size incorrect");

        assertEq(testParams[0].principal / assetToSharesRatio, balances[0], "balance mismatch period 0");
        assertEq(testParams[1].principal / assetToSharesRatio, balances[1], "balance mismatch period 1");
        assertEq(testParams[2].principal / assetToSharesRatio, balances[2], "balance mismatch period 2");

        return balances;
    }

    function _createMultiTokenVault(IERC20Metadata asset_, uint256 assetToSharesRatio, uint256 yieldPercentage)
        internal
        returns (IMultiTokenVault)
    {
        MultiTokenVaultDailyPeriods vaultImpl = new MultiTokenVaultDailyPeriods();
        return MultiTokenVaultDailyPeriods(
            address(
                new ERC1967Proxy(
                    address(vaultImpl),
                    abi.encodeWithSelector(vaultImpl.initialize.selector, asset_, assetToSharesRatio, yieldPercentage)
                )
            )
        );
    }

    // ========================= Verifiers =========================

    function testVaultAtOffsets(address account, IVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        override(IVaultTestBase, IVaultTestVerifier)
        returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_)
    {
        return IVaultTestBase.testVaultAtOffsets(account, vault, testParam);
    }

    function _testDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) internal virtual override(IVaultTestBase, IVaultTestVerifier) returns (uint256 actualSharesAtPeriod_) {
        return IVaultTestBase._testDepositOnly(depositUsers, vault, testParam);
    }

    function _testRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual override(IVaultTestBase, IVaultTestVerifier) returns (uint256 actualAssetsAtPeriod_) {
        return IVaultTestBase._testRedeemOnly(redeemUsers, vault, testParam, sharesToRedeemAtPeriod);
    }

    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        override(IVaultTestBase, IVaultTestVerifier)
        returns (uint256 expectedShares)
    {
        MultiTokenVaultDailyPeriods multiTokenVault = MultiTokenVaultDailyPeriods(address(vault));

        return testParam.principal / multiTokenVault.ASSET_TO_SHARES_RATIO();
    }

    function _expectedReturns(uint256, /* shares */ IVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        override(IVaultTestBase, IVaultTestVerifier)
        returns (uint256 expectedReturns_)
    {
        return MultiTokenVaultDailyPeriods(address(vault))._yieldStrategy().calcYield(
            address(vault), testParam.principal, testParam.depositPeriod, testParam.redeemPeriod
        );
    }

    function _warpToPeriod(IVault vault, uint256 timePeriod) internal override(IVaultTestBase, IVaultTestVerifier) {
        MultiTokenVaultDailyPeriods multiTokenVault = MultiTokenVaultDailyPeriods(address(vault));

        uint256 warpToTimeInSeconds = multiTokenVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }

    function _vault() internal virtual override returns (IVault) {
        return _multiTokenVault;
    }
}
