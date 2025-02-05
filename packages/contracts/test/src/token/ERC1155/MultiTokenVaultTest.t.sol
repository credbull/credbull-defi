// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IVault } from "@test/test/token/ERC4626/IVault.sol";

import { IVaultTestSuite } from "@test/src/token/ERC4626/IVaultTestSuite.t.sol";

import { IMultiTokenVaultVerifierBase } from "@test/test/token/ERC1155/IMultiTokenVaultVerifierBase.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";
import { MultiTokenVaultDailyPeriods } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriods.t.sol";
import { IMultiTokenVaultVerifierBase } from "@test/test/token/ERC1155/IMultiTokenVaultVerifierBase.t.sol";
import { MultiTokenVaultDailyPeriodsVerifier } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriodsVerifier.t.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MultiTokenVaultTest is IVaultTestSuite {
    using TestParamSet for TestParamSet.TestParam[];

    uint256 public constant TEST_ASSET_TO_SHARE_RATIO = 3;

    IMultiTokenVault private _multiTokenVault;
    IMultiTokenVaultVerifierBase private _multiTokenVerifier;

    function setUp() public virtual override {
        _multiTokenVault = _createMultiTokenVault(_createAsset(_owner), TEST_ASSET_TO_SHARE_RATIO, 10);
        _multiTokenVerifier = new MultiTokenVaultDailyPeriodsVerifier();

        init(_toIVault(_multiTokenVault), _multiTokenVerifier);
    }

    /// @dev - TODO - directly inherit from IVault with next version
    function _toIVault(IMultiTokenVault multiTokenVault) internal pure returns (IVault vault_) {
        return IVault(address(multiTokenVault));
    }

    function test__MultiTokenVaultTest__DepositBatchRedeemOnTenor2() public {
        test__IVaultSuite__DepositBatchRedeemOnTenor2();
    }

    function test__MultiTokenVaultTest__RedeemBeforeDepositPeriodReverts() public {
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
        _multiTokenVault.redeemForDepositPeriod(1, _alice, _alice, testParam.depositPeriod, testParam.redeemPeriod);
    }

    function test__MultiTokenVaultTest__CurrentBeforeRedeemPeriodReverts() public {
        TestParamSet.TestParam memory testParam =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: 3 });

        uint256 currentPeriod = testParam.redeemPeriod - 1;

        _multiTokenVerifier._warpToPeriod(_toIVault(_multiTokenVault), currentPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__RedeemTimePeriodNotSupported.selector,
                _alice,
                currentPeriod,
                testParam.redeemPeriod
            )
        );
        _multiTokenVault.redeemForDepositPeriod(1, _alice, _alice, testParam.depositPeriod, testParam.redeemPeriod);
    }

    function test__MultiTokenVaultTest__RedeemOverMaxSharesReverts() public {
        TestParamSet.TestParam memory testParam =
            TestParamSet.TestParam({ principal: 1001 * _scale, depositPeriod: 1, redeemPeriod: 3 });

        uint256 sharesToRedeem = 1;

        _multiTokenVerifier._warpToPeriod(_toIVault(_multiTokenVault), testParam.redeemPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__ExceededMaxRedeem.selector,
                _alice,
                testParam.depositPeriod,
                sharesToRedeem,
                0
            )
        );
        _multiTokenVault.redeemForDepositPeriod(
            sharesToRedeem, _alice, _alice, testParam.depositPeriod, testParam.redeemPeriod
        );
    }

    function test__MultiTokenVaultTest__RedeemWithAllowance() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: 10 });

        vm.prank(_alice);
        _asset.approve(address(_multiTokenVault), testParams.principal); // grant _multiTokenVault allowance on alice's principal
        _transferFromTokenOwner(_asset, address(_multiTokenVault), testParams.principal); // transfer funds to cover redeem

        vm.prank(_alice);
        uint256 shares = _multiTokenVault.deposit(testParams.principal, _alice);

        // ------------ redeem - without allowance ------------
        _multiTokenVerifier._warpToPeriod(_toIVault(_multiTokenVault), testParams.redeemPeriod);

        address allowanceAccount = makeAddr("allowanceAccount");

        // should fail, no allowance given yet
        vm.prank(allowanceAccount);
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__CallerMissingApprovalForAll.selector, allowanceAccount, _alice
            )
        );
        _multiTokenVault.redeemForDepositPeriod(
            shares, _alice, _alice, testParams.depositPeriod, testParams.redeemPeriod
        );

        // ------------ redeem - with allowance ------------
        vm.prank(_alice);
        _multiTokenVault.setApprovalForAll(allowanceAccount, true); // grant allowance

        // should succeed - allowance granted
        address receiverAccount = makeAddr("receiver");
        vm.prank(allowanceAccount);
        uint256 assets = _multiTokenVault.redeemForDepositPeriod(
            shares, receiverAccount, _alice, testParams.depositPeriod, testParams.redeemPeriod
        );

        assertEq(assets, _asset.balanceOf(receiverAccount), "receiver did not receive assets");
    }

    function test__MultiTokenVaultTest__BatchFunctions() public {
        uint256 assetToSharesRatio = TEST_ASSET_TO_SHARE_RATIO;
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

        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        uint256[] memory shares =
            _multiTokenVerifier._verifyDepositOnlyBatch(testUsers, _toIVault(_multiTokenVault), _batchTestParams);
        uint256[] memory depositPeriods = _batchTestParams.depositPeriods();
        uint256[] memory depositPeriodsToRevert = _batchTestParamsToRevert.depositPeriods();

        // ------------------------ batch convert to assets ------------------------
        uint256[] memory assets =
            _multiTokenVault.convertToAssetsForDepositPeriodBatch(shares, depositPeriods, redeemPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__InvalidArrayLength.selector,
                depositPeriodsToRevert.length,
                shares.length
            )
        );
        _multiTokenVault.convertToAssetsForDepositPeriodBatch(shares, depositPeriodsToRevert, redeemPeriod);

        assertEq(3, assets.length, "assets are wrong length");
        assertEq(
            assets[0],
            _multiTokenVault.convertToAssetsForDepositPeriod(shares[0], depositPeriods[0], redeemPeriod),
            "asset mismatch period 0"
        );
        assertEq(
            assets[1],
            _multiTokenVault.convertToAssetsForDepositPeriod(shares[1], depositPeriods[1], redeemPeriod),
            "asset mismatch period 1"
        );
        assertEq(
            assets[2],
            _multiTokenVault.convertToAssetsForDepositPeriod(shares[2], depositPeriods[2], redeemPeriod),
            "asset mismatch period 2"
        );

        // ------------------------ batch approvalForAll safeBatchTransferFrom balance ------------------------
        uint256[] memory aliceBalances =
            _testBalanceOfBatch(_alice, _multiTokenVault, _batchTestParams, assetToSharesRatio);

        // have alice approve bob for all
        vm.prank(_alice);
        _multiTokenVault.setApprovalForAll(_bob, true);

        // now bob can transfer on behalf of alice to charlie
        vm.prank(_bob);
        _multiTokenVault.safeBatchTransferFrom(_alice, _charlie, depositPeriods, aliceBalances, "");

        _testBalanceOfBatch(_charlie, _multiTokenVault, _batchTestParams, assetToSharesRatio); // verify bob
    }

    function test__MultiTokenVaultTest__ZeroOrOneAssetsShouldGiveZeroShares() public {
        TestParamSet.TestParam memory zeroPrincipal =
            TestParamSet.TestParam({ principal: 0, depositPeriod: 10, redeemPeriod: 21 });
        TestParamSet.TestParam memory onePrincipal =
            TestParamSet.TestParam({ principal: 1, depositPeriod: 10, redeemPeriod: 21 });

        address vaultAddress = address(_multiTokenVault);

        vm.startPrank(_alice);
        _asset.approve(vaultAddress, onePrincipal.principal);

        // ------------- test for deposit of 0 -------------
        vm.startPrank(_alice);
        uint256 sharesFromZeroPrincipal = _multiTokenVault.deposit(zeroPrincipal.principal, _alice);
        vm.stopPrank();

        assertEq(zeroPrincipal.principal, _asset.balanceOf(vaultAddress), "_multiTokenVault should have the asset");
        assertEq(0, sharesFromZeroPrincipal, "deposit of zero assets should give zero shares");

        // ------------- test for deposit of 1  -------------
        vm.startPrank(_alice);
        uint256 sharesFromOnePrincipal = _multiTokenVault.deposit(onePrincipal.principal, _alice);
        vm.stopPrank();

        // 1 asset converts to 0 shares with any assetToShare ratio > 0.  e.g.: 1 asset / 2 = 0 shares rounded down.
        assertEq(onePrincipal.principal, _asset.balanceOf(vaultAddress), "_multiTokenVault should have the asset");
        assertEq(0, sharesFromOnePrincipal, "deposit of fractional assets should give zero shares");
    }

    function test__MultiTokenVaultTest__SafeTransferFrom() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: 10 });

        // Step 2: Deposit some assets for _alice to receive shares
        vm.startPrank(_alice);
        _asset.approve(address(_multiTokenVault), testParams.principal);
        uint256 shares = _multiTokenVault.deposit(testParams.principal, _alice);
        vm.stopPrank();

        // Verify _alice has received the shares
        assertEq(
            _multiTokenVault.balanceOf(_alice, testParams.depositPeriod),
            shares,
            "_alice should have the shares after deposit"
        );

        // Step 3: Perform the safe transfer from _alice to _bob
        vm.startPrank(_alice);
        _multiTokenVault.safeTransferFrom(_alice, _bob, testParams.depositPeriod, shares, "");
        vm.stopPrank();

        // Step 4: Verify the transfer was successful
        assertEq(
            _multiTokenVault.balanceOf(_alice, testParams.depositPeriod),
            0,
            "_alice should have no shares after transfer"
        );
        assertEq(
            _multiTokenVault.balanceOf(_bob, testParams.depositPeriod),
            shares,
            "_bob should have the transferred shares"
        );
    }

    function test__MultiTokenVaultTest__IsApprovedForAll() public {
        address operator = makeAddr("operator");

        // Set approval
        vm.prank(_alice);
        _multiTokenVault.setApprovalForAll(operator, true);

        // Check if the operator is approved
        bool isApproved = _multiTokenVault.isApprovedForAll(_alice, operator);
        assertEq(isApproved, true, "Operator should be approved");

        // Revoke approval and check
        vm.prank(_alice);
        _multiTokenVault.setApprovalForAll(operator, false);
        isApproved = _multiTokenVault.isApprovedForAll(_alice, operator);
        assertEq(isApproved, false, "Operator should not be approved");
    }

    function test__MultiTokenVaultTest__MaxDeposit() public view {
        uint256 maxDepositValue = _multiTokenVault.maxDeposit(_alice);
        assertEq(maxDepositValue, type(uint256).max, "Max deposit should be uint256 max");
    }

    function test__MultiTokenVaultTest__MaxRedeemAtPeriod() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 0, redeemPeriod: 30 });

        // Alice deposits assets and receives shares
        vm.startPrank(_alice);
        _asset.approve(address(_multiTokenVault), testParams.principal);
        uint256 shares = _multiTokenVault.deposit(testParams.principal, _alice);
        vm.stopPrank();

        // Check max redeemable shares for the deposit period
        uint256 maxShares = _multiTokenVault.maxRedeemAtPeriod(_alice, testParams.depositPeriod); // Assuming deposit period = 1
        assertEq(maxShares, shares, "Max redeemable shares did not match the deposited shares");
    }

    function _testBalanceOfBatch(
        address account,
        IMultiTokenVault multiTokenVault_,
        TestParamSet.TestParam[] memory testParams,
        uint256 assetToSharesRatio
    ) internal view returns (uint256[] memory balances_) {
        address[] memory accounts = testParams.accountArray(account);
        uint256[] memory balances = multiTokenVault_.balanceOfBatch(accounts, testParams.depositPeriods());
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
}
