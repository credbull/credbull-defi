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

    function test__MultiTokenVaulTest__SimpleDeposit() public {
        uint256 assetToSharesRatio = 1;

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

    function test__MultiTokenVaulTest__DepositAndRedeem() public {
        uint256 assetToSharesRatio = 1;

        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);

        MultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        testVaultAtOffsets(_charlie, vault, _testParams1);
    }

    function test__MultiTokenVaulTest__RedeemBeforeDepositPeriodReverts() public {
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

    function test__MultiTokenVaulTest__CurrentBeforeRedeemPeriodReverts() public {
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

    function test__MultiTokenVaulTest__RedeemOverMaxSharesReverts() public {
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

    function test__MultiTokenVaulTest__MultipleDepositsAndRedeem() public {
        uint256 assetToSharesRatio = 2;

        // setup
        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        // verify deposit - period 1
        uint256 deposit1Shares = _testDepositOnly(_alice, vault, _testParams1);
        assertEq(_testParams1.principal / assetToSharesRatio, deposit1Shares, "deposit shares incorrect at period 1");
        assertEq(
            deposit1Shares,
            vault.sharesAtPeriod(_alice, _testParams1.depositPeriod),
            "getSharesAtPeriod incorrect at period 1"
        );
        assertEq(deposit1Shares, vault.balanceOf(_alice, _testParams1.depositPeriod), "balance incorrect at period 1");
        assertEq(deposit1Shares, vault.balanceOf(_alice, _testParams1.depositPeriod), "balance incorrect at period 1");

        // verify deposit - period 2
        uint256 deposit2Shares = _testDepositOnly(_alice, vault, _testParams2);
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
        uint256 deposit1Assets = _testRedeemOnly(_alice, vault, _testParams1, deposit1Shares);
        assertApproxEqAbs(
            _testParams1.principal + deposit1ExpectedYield,
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify redeem - period 2
        uint256 deposit2Assets = _testRedeemOnly(_alice, vault, _testParams2, deposit2Shares);
        assertApproxEqAbs(
            _testParams2.principal + _expectedReturns(deposit1Shares, vault, _testParams2),
            deposit2Assets,
            TOLERANCE,
            "deposit2 deposit assets incorrect"
        );

        testVaultAtOffsets(_alice, vault, _testParams1);
        testVaultAtOffsets(_alice, vault, _testParams2);
    }

    function test__MultiTokenVaulTest__BatchFunctions() public {
        uint256 assetToSharesRatio = 2;
        uint256 redeemPeriod = 2001;

        TestParamSet.TestParam[] memory _batchTestParams = new TestParamSet.TestParam[](3);

        _batchTestParams[0] =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: redeemPeriod });
        _batchTestParams[1] =
            TestParamSet.TestParam({ principal: 2002 * _scale, depositPeriod: 202, redeemPeriod: redeemPeriod });
        _batchTestParams[2] =
            TestParamSet.TestParam({ principal: 3003 * _scale, depositPeriod: 303, redeemPeriod: redeemPeriod });

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        uint256[] memory shares = _testDepositOnly(_alice, vault, _batchTestParams);
        uint256[] memory depositPeriods = _batchTestParams.depositPeriods();

        // ------------------------ batch convert to assets ------------------------
        uint256[] memory assets = vault.convertToAssetsForDepositPeriodBatch(shares, depositPeriods, redeemPeriod);

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
