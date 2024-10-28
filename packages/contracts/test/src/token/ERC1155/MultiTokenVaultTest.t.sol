// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IMultiTokenVaultTestBase } from "@test/test/token/ERC1155/IMultiTokenVaultTestBase.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";
import { MultiTokenVaultDailyPeriods } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriods.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MultiTokenVaultTest is IMultiTokenVaultTestBase {
    using TestParamSet for TestParamSet.TestParam[];

    IERC20Metadata internal _asset;
    uint256 internal _scale;

    address private _owner = makeAddr("owner");
    address private _alice = makeAddr("alice");
    address private _bob = makeAddr("bob");
    address private _charlie = makeAddr("charlie");

    TestParamSet.TestParam internal _testParams1;
    TestParamSet.TestParam internal _testParams2;
    TestParamSet.TestParam internal _testParams3;

    function setUp() public virtual {
        vm.prank(_owner);
        _asset = new SimpleUSDC(_owner, 1_000_000 ether);

        _scale = 10 ** _asset.decimals();
        _transferAndAssert(_asset, _owner, _alice, 100_000 * _scale);

        _testParams1 = TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 21 });
        _testParams2 = TestParamSet.TestParam({ principal: 300 * _scale, depositPeriod: 15, redeemPeriod: 17 });
        _testParams3 = TestParamSet.TestParam({ principal: 700 * _scale, depositPeriod: 30, redeemPeriod: 55 });
    }

    function test__MultiTokenVaultTest__SimpleDeposit() public {
        uint256 assetToSharesRatio = 2;

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        address vaultAddress = address(vault);

        assertEq(0, _asset.allowance(_alice, vaultAddress), "vault shouldn't have an allowance to start");
        assertEq(0, _asset.balanceOf(vaultAddress), "vault shouldn't have a balance to start");

        vm.startPrank(_alice);
        _asset.approve(vaultAddress, _testParams1.principal);

        assertEq(_testParams1.principal, _asset.allowance(_alice, vaultAddress), "vault should have allowance");
        vm.stopPrank();

        vm.startPrank(_alice);
        vault.deposit(_testParams1.principal, _alice);
        vm.stopPrank();

        assertEq(_testParams1.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, _asset.allowance(_alice, vaultAddress), "vault shouldn't have an allowance after deposit");

        testVaultAtOffsets(_alice, vault, _testParams1);
    }

    function test__MultiTokenVaultTest__RevertWhen_DepositExceedsMax() public {
        uint256 assetToSharesRatio = 2;

        MultiTokenVaultDailyPeriods vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        uint256 _maxDeposit = 250 * _scale;
        vault.setMaxDeposit(_maxDeposit);

        address vaultAddress = address(vault);
        vm.startPrank(_alice);
        _asset.approve(vaultAddress, _testParams1.principal);

        // deposit amount > max deposit amount should fail.
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__ExceededMaxDeposit.selector,
                _alice,
                vault.currentPeriodsElapsed(),
                _testParams1.principal,
                _maxDeposit
            )
        );
        vault.deposit(_testParams1.principal, _alice);
        vm.stopPrank();
    }

    function test__MultiTokenVaultTest__DepositAndRedeem() public {
        uint256 assetToSharesRatio = 3;

        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);

        MultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        testVaultAtOffsets(_charlie, vault, _testParams1);
    }

    function test__MultiTokenVaultTest__RedeemBeforeDepositPeriodReverts() public {
        MultiTokenVault vault = _createMultiTokenVault(_asset, 1, 10);

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
        MultiTokenVault vault = _createMultiTokenVault(_asset, 1, 10);

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
        MultiTokenVault vault = _createMultiTokenVault(_asset, 1, 10);

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

    function test__MultiTokenVaultTest__MultipleDepositsAndRedeem() public {
        uint256 assetToSharesRatio = 4;

        // setup
        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        // verify deposit - period 1
        uint256 deposit1Shares = _testDepositOnly(testUsers, vault, _testParams1);
        assertEq(_testParams1.principal / assetToSharesRatio, deposit1Shares, "deposit shares incorrect at period 1");
        assertEq(
            deposit1Shares,
            vault.sharesAtPeriod(_alice, _testParams1.depositPeriod),
            "getSharesAtPeriod incorrect at period 1"
        );
        assertEq(deposit1Shares, vault.balanceOf(_alice, _testParams1.depositPeriod), "balance incorrect at period 1");
        assertEq(deposit1Shares, vault.balanceOf(_alice, _testParams1.depositPeriod), "balance incorrect at period 1");

        // verify deposit - period 2
        uint256 deposit2Shares = _testDepositOnly(testUsers, vault, _testParams2);
        assertEq(_testParams2.principal / assetToSharesRatio, deposit2Shares, "deposit shares incorrect at period 2");
        assertEq(
            deposit2Shares,
            vault.sharesAtPeriod(_alice, _testParams2.depositPeriod),
            "getSharesAtPeriod incorrect at period 2"
        );
        assertEq(deposit2Shares, vault.balanceOf(_alice, _testParams2.depositPeriod), "balance incorrect at period 2");

        // New check for sharesAtPeriods
        _warpToPeriod(vault, _testParams2.depositPeriod); // warp to deposit2Period

        // verify redeem - period 1
        uint256 deposit1ExpectedYield = _expectedReturns(deposit1Shares, vault, _testParams1);
        uint256 deposit1Assets = _testRedeemOnly(testUsers, vault, _testParams1, deposit1Shares);
        assertApproxEqAbs(
            _testParams1.principal + deposit1ExpectedYield,
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify redeem - period 2
        uint256 deposit2Assets = _testRedeemOnly(testUsers, vault, _testParams2, deposit2Shares);
        assertApproxEqAbs(
            _testParams2.principal + _expectedReturns(deposit1Shares, vault, _testParams2),
            deposit2Assets,
            TOLERANCE,
            "deposit2 deposit assets incorrect"
        );

        testVaultAtOffsets(_alice, vault, _testParams1);
        testVaultAtOffsets(_alice, vault, _testParams2);
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

    function test__MultiTokenVaultTest__ShouldReturnZeroOnFractionalShareDeposit() public {
        uint256 assetToSharesRatio = 2;

        TestParamSet.TestParam memory zeroPrincipal =
            TestParamSet.TestParam({ principal: 0, depositPeriod: 10, redeemPeriod: 21 });
        TestParamSet.TestParam memory fractionalPrincipal =
            TestParamSet.TestParam({ principal: 1, depositPeriod: 10, redeemPeriod: 21 });

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        address vaultAddress = address(vault);

        vm.startPrank(_alice);
        _asset.approve(vaultAddress, fractionalPrincipal.principal);

        // ------------- test for zero deposit -------------
        vm.startPrank(_alice);
        uint256 zeroAssets = vault.deposit(zeroPrincipal.principal, _alice);
        vm.stopPrank();

        assertEq(zeroPrincipal.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, zeroAssets, "zero shares should give zero assets");

        // ------------- test for fractional deposit -------------
        vm.startPrank(_alice);
        uint256 fractionalAssets = vault.deposit(fractionalPrincipal.principal, _alice);
        vm.stopPrank();

        assertEq(fractionalPrincipal.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, fractionalAssets, "fractional shares should give zero assets");
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

    function _expectedReturns(uint256, /* shares */ IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        virtual
        override
        returns (uint256 expectedReturns_)
    {
        return MultiTokenVaultDailyPeriods(address(vault)).calcYield(
            testParam.principal, testParam.depositPeriod, testParam.redeemPeriod
        );
    }

    function _warpToPeriod(IMultiTokenVault vault, uint256 timePeriod) internal override {
        MultiTokenVaultDailyPeriods(address(vault)).setCurrentPeriodsElapsed(timePeriod);
    }

    function _createMultiTokenVault(IERC20Metadata asset_, uint256 assetToSharesRatio, uint256 yieldPercentage)
        internal
        virtual
        returns (MultiTokenVaultDailyPeriods)
    {
        MultiTokenVaultDailyPeriods _vault = new MultiTokenVaultDailyPeriods();

        return MultiTokenVaultDailyPeriods(
            address(
                new ERC1967Proxy(
                    address(_vault),
                    abi.encodeWithSelector(_vault.initialize.selector, asset_, assetToSharesRatio, yieldPercentage)
                )
            )
        );
    }
}
