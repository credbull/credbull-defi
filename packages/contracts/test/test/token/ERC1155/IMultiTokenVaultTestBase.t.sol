// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { Test } from "forge-std/Test.sol";

abstract contract IMultiTokenVaultTestBase is Test {
    using TestParamSet for TestParamSet.TestParam[];

    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000010

    /// @dev test the vault at the given test parameters
    function testVault(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory testParams
    ) internal returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_) {
        // previews okay to test individually.  don't update vault state.
        for (uint256 i = 0; i < testParams.length; i++) {
            TestParamSet.TestParam memory testParam = testParams[i];
            _testConvertToAssetAndSharesAtPeriod(vault, testParam); // previews only, account agnostic
            _testPreviewDepositAndPreviewRedeem(vault, testParam); // previews only, account agnostic
        }

        // capture vault state before warping around
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- deposits w/ redeems per deposit -------------------
        // NB - test all of the deposits BEFORE redeems.  verifies no side-effects from deposits when redeeming.
        uint256[] memory sharesAtPeriods = _testDepositOnly(depositUsers, vault, testParams);

        // NB - test all of the redeems AFTER deposits.  verifies no side-effects from deposits when redeeming.
        uint256[] memory assetsAtPeriods = _testRedeemOnly(redeemUsers, vault, testParams, sharesAtPeriods);

        // ------------------- deposits w/ redeems across multiple deposits -------------------
        _testVaultCombineDepositsForRedeem(depositUsers, redeemUsers, vault, testParams, 2);

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return (sharesAtPeriods, assetsAtPeriods);
    }

    /// @dev test the vault deposits and redeems across multiple deposit periods
    function _testVaultCombineDepositsForRedeem(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory testParams,
        uint256 splitBefore
    ) internal returns (uint256[] memory sharesAtPeriods_, uint256 assetsAtPeriods1_, uint256 assetsAtPeriods2_) {
        // NB - test all of the deposits BEFORE redeems.  verifies no side-effects from deposits when redeeming.
        uint256[] memory sharesAtPeriods = _testDepositOnly(depositUsers, vault, testParams);

        // NB - test all of the redeems AFTER deposits.  verifies no side-effects from deposits when redeeming.
        uint256 finalRedeemPeriod = testParams.latestRedeemPeriod();

        // split into two batches
        (TestParamSet.TestParam[] memory redeemParams1, TestParamSet.TestParam[] memory redeemParams2) =
            testParams._splitBefore(splitBefore);

        assertLe(2, redeemParams1.length, "redeem params array 1 should have multiple params");
        assertLe(2, redeemParams2.length, "redeem params array 2 should have multiple params");

        uint256 partialRedeemPeriod = finalRedeemPeriod - 2;

        uint256 assetsAtPeriods1 = _testRedeemMultiDeposit(redeemUsers, vault, redeemParams1, partialRedeemPeriod);
        uint256 assetsAtPeriods2 = _testRedeemMultiDeposit(redeemUsers, vault, redeemParams2, finalRedeemPeriod);

        return (sharesAtPeriods, assetsAtPeriods1, assetsAtPeriods2);
    }

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtOffsets(address account, IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_)
    {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _createTestUsers(account);

        return testVaultAtOffsets(depositUsers, redeemUsers, vault, testParam);
    }

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtOffsets(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam memory testParam
    ) internal returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_) {
        TestParamSet.TestParam[] memory testParams = TestParamSet.toOffsetArray(testParam);
        return testVault(depositUsers, redeemUsers, vault, testParams);
    }

    /// @dev verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function _testConvertToAssetAndSharesAtPeriod(IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed(); // save previous state for later

        // ------------------- check toShares/toAssets - specified period -------------------
        actualSharesAtPeriod = vault.convertToSharesForDepositPeriod(testParam.principal, testParam.depositPeriod);
        actualAssetsAtPeriod =
            vault.convertToAssetsForDepositPeriod(actualSharesAtPeriod, testParam.depositPeriod, testParam.redeemPeriod);

        uint256 expectedAssetsAtRedeem = testParam.principal + _expectedReturns(actualSharesAtPeriod, vault, testParam);

        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("yield does not equal principal + interest", vault, testParam.depositPeriod)
        );

        // ------------------- check toShares/toAssets - current period -------------------
        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit
        uint256 actualShares = vault.convertToShares(testParam.principal);

        _warpToPeriod(vault, testParam.redeemPeriod); // warp to redeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(actualShares, testParam.depositPeriod),
            TOLERANCE,
            _assertMsg("toShares/toAssets yield does not equal principal + interest", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore to previous state

        return (actualAssetsAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function _testPreviewDepositAndPreviewRedeem(IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit
        actualSharesAtPeriod = vault.previewDeposit(testParam.principal);

        _warpToPeriod(vault, testParam.redeemPeriod); // warp to redeem / withdraw
        actualAssetsAtPeriod = vault.previewRedeemForDepositPeriod(actualSharesAtPeriod, testParam.depositPeriod);

        uint256 expectedAssetsAtRedeem = testParam.principal + _expectedReturns(actualSharesAtPeriod, vault, testParam);

        // check previewRedeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.previewRedeemForDepositPeriod(actualSharesAtPeriod, testParam.depositPeriod),
            TOLERANCE,
            _assertMsg(
                "previewDeposit/previewRedeem yield does not equal principal + interest", vault, testParam.depositPeriod
            )
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return (actualSharesAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev verify deposit.  updates vault assets and shares.
    function _testDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory testParams
    ) internal virtual returns (uint256[] memory sharesAtPeriod_) {
        uint256[] memory sharesAtPeriod = new uint256[](testParams.length);
        for (uint256 i = 0; i < testParams.length; i++) {
            sharesAtPeriod[i] = _testDepositOnly(depositUsers, vault, testParams[i]);
        }
        return sharesAtPeriod;
    }

    /// @dev verify deposit.  updates vault assets and shares.
    function _testDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam memory testParam
    ) internal virtual returns (uint256 actualSharesAtPeriod_) {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.sharesAtPeriod(depositUsers.tokenReceiver, testParam.depositPeriod);

        // ------------------- deposit -------------------
        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit period

        assertGe(
            asset.balanceOf(depositUsers.tokenOwner),
            testParam.principal,
            _assertMsg("not enough assets for deposit ", vault, testParam.depositPeriod)
        );
        vm.prank(depositUsers.tokenOwner); // tokenOwner here is the owner of the USDC
        asset.approve(address(vault), testParam.principal); // grant the vault allowance

        vm.prank(depositUsers.tokenOwner); // tokenOwner here is the owner of the USDC
        uint256 actualSharesAtPeriod = vault.deposit(testParam.principal, depositUsers.tokenReceiver); // now deposit

        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.sharesAtPeriod(depositUsers.tokenReceiver, testParam.depositPeriod),
            _assertMsg(
                "receiver did not receive the correct vault shares - sharesAtPeriod", vault, testParam.depositPeriod
            )
        );
        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.balanceOf(depositUsers.tokenReceiver, testParam.depositPeriod),
            _assertMsg("receiver did not receive the correct vault shares - balanceOf ", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return actualSharesAtPeriod;
    }

    /// @dev verify redeem.  updates vault assets and shares.
    function _testRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory testParams,
        uint256[] memory sharesAtPeriods
    ) internal virtual returns (uint256[] memory assetsAtPeriods_) {
        uint256[] memory assetsAtPeriods = new uint256[](testParams.length);
        for (uint256 i = 0; i < testParams.length; i++) {
            assetsAtPeriods[i] = _testRedeemOnly(redeemUsers, vault, testParams[i], sharesAtPeriods[i]);
        }
        return assetsAtPeriods;
    }

    /// @dev verify redeem.  updates vault assets and shares.
    function _testRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual returns (uint256 actualAssetsAtPeriod_) {
        IERC20 asset = IERC20(vault.asset());

        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- prep redeem -------------------
        uint256 assetBalanceBeforeRedeem = asset.balanceOf(redeemUsers.tokenReceiver);
        uint256 shareBalanceBeforeRedeem = vault.balanceOf(redeemUsers.tokenOwner, testParam.depositPeriod);
        uint256 expectedReturns = _expectedReturns(sharesToRedeemAtPeriod, vault, testParam);

        _transferFromTokenOwner(asset, address(vault), expectedReturns);

        // ------------------- redeem -------------------
        _warpToPeriod(vault, testParam.redeemPeriod); // warp the vault to redeem period

        // authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, true);

        vm.startPrank(redeemUsers.tokenOperator);
        uint256 actualAssetsAtPeriod = vault.redeemForDepositPeriod(
            sharesToRedeemAtPeriod, redeemUsers.tokenReceiver, redeemUsers.tokenOwner, testParam.depositPeriod
        );
        vm.stopPrank();

        // de-authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, false);

        assertApproxEqAbs(
            testParam.principal + expectedReturns,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("assets does not equal principal + yield", vault, testParam.depositPeriod)
        );

        // verify the token owner shares reduced
        assertEq(
            shareBalanceBeforeRedeem - sharesToRedeemAtPeriod,
            vault.balanceOf(redeemUsers.tokenOwner, testParam.depositPeriod),
            _assertMsg("shares not reduced by redeem amount", vault, testParam.depositPeriod)
        );

        // verify the receiver has the USDC back
        assertApproxEqAbs(
            assetBalanceBeforeRedeem + testParam.principal + expectedReturns,
            asset.balanceOf(redeemUsers.tokenReceiver),
            TOLERANCE,
            _assertMsg("receiver did not receive the correct yield", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore the vault to previous state

        return actualAssetsAtPeriod;
    }

    /// @dev - requestRedeem over multiple deposit and principals into one requestRedeemPeriod
    function _testRedeemMultiDeposit(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod // we are testing multiple deposits into one redeemPeriod
    ) internal virtual returns (uint256 assets_) {
        _warpToPeriod(vault, redeemPeriod);

        IERC20 asset = IERC20(vault.asset());

        uint256 prevAssetBalance = asset.balanceOf(redeemUsers.tokenReceiver);
        uint256[] memory prevSharesBalance = vault.balanceOfBatch(
            depositTestParams.accountArray(redeemUsers.tokenOwner), depositTestParams.depositPeriods()
        );

        // get the vault enough to cover redeems
        _transferFromTokenOwner(asset, address(vault), depositTestParams.totalPrincipal()); // this will give the vault 2x principal

        uint256 assets = _vaultRedeemBatch(redeemUsers, vault, depositTestParams, redeemPeriod);

        assertEq(
            prevAssetBalance + assets,
            asset.balanceOf(redeemUsers.tokenReceiver),
            "receiver did not receive assets - redeem on multi deposit"
        );

        // check share balances reduced on the owner
        uint256[] memory sharesBalance = vault.balanceOfBatch(
            depositTestParams.accountArray(redeemUsers.tokenOwner), depositTestParams.depositPeriods()
        );

        assertEq(prevSharesBalance.length, sharesBalance.length, "mismatch on share balance");

        for (uint256 i = 0; i < prevSharesBalance.length; ++i) {
            uint256 sharesAtPeriod = vault.convertToSharesForDepositPeriod(
                depositTestParams[i].principal, depositTestParams[i].depositPeriod
            );
            assertEq(prevSharesBalance[i] - sharesAtPeriod, sharesBalance[i], "token owner shares balance incorrect");
        }

        return assets;
    }

    /// @dev vault redeem across multiple deposit periods. (if supported)
    function _vaultRedeemBatch(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod
    ) internal virtual returns (uint256 assets_) {
        _warpToPeriod(vault, redeemPeriod); // warp the vault to redeem period

        // authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, true);

        uint256 assets = 0;
        vm.startPrank(redeemUsers.tokenOperator);
        // IMultiTokenVault doesn't support redeeming across deposit periods.  redeem period by period instead.
        for (uint256 i = 0; i < depositTestParams.length; ++i) {
            uint256 depositPeriod = depositTestParams[i].depositPeriod;
            uint256 sharesAtPeriod =
                vault.convertToSharesForDepositPeriod(depositTestParams[i].principal, depositPeriod);

            assets += vault.redeemForDepositPeriod(
                sharesAtPeriod, redeemUsers.tokenReceiver, redeemUsers.tokenOwner, depositTestParams[i].depositPeriod
            );
        }
        vm.stopPrank();

        // de-authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, false);

        return assets;
    }

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    function _expectedReturns(uint256 shares, IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        virtual
        returns (uint256 expectedReturns_);

    /// @dev warp the vault to the given timePeriod for testing purposes
    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IMultiTokenVault, /* vault */ uint256 timePeriod) internal virtual {
        vm.warp(Timer.timestamp() + timePeriod * 24 hours);
    }

    /// @dev - creates a TestParam for testing
    function _createTestParam(uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
        internal
        pure
        returns (TestParamSet.TestParam memory testParam)
    {
        return
            TestParamSet.TestParam({ principal: principal, depositPeriod: depositPeriod, redeemPeriod: redeemPeriod });
    }

    // simple scenario with only one user
    function _createTestUsers(address account)
        internal
        virtual
        returns (TestParamSet.TestUsers memory depositUsers_, TestParamSet.TestUsers memory redeemUsers_)
    {
        // Convert the address to a string and then to bytes
        string memory accountStr = vm.toString(account);

        TestParamSet.TestUsers memory depositUsers = TestParamSet.TestUsers({
            tokenOwner: account, // owns tokens, can specify who can receive tokens
            tokenReceiver: makeAddr(string.concat("depositTokenReceiver-", accountStr)), // receiver of tokens from the tokenOwner
            tokenOperator: makeAddr(string.concat("depositTokenOperator-", accountStr)) // granted allowance by tokenOwner to act on their behalf
         });

        TestParamSet.TestUsers memory redeemUsers = TestParamSet.TestUsers({
            tokenOwner: depositUsers.tokenReceiver, // on deposit, the tokenReceiver receives (owns) the tokens
            tokenReceiver: account, // virtuous cycle, the account receives the returns in the end
            tokenOperator: makeAddr(string.concat("redeemTokenOperator-", accountStr)) // granted allowance by tokenOwner to act on their behalf
         });

        return (depositUsers, redeemUsers);
    }

    /// @dev - creates a message string for assertions
    function _assertMsg(string memory prefix, IMultiTokenVault vault, uint256 numPeriods)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prefix, " Vault= ", vm.toString(address(vault)), " timePeriod= ", vm.toString(numPeriods));
    }

    /// @dev - transfer from the owner of the IERC20 `token` to the `toAddress`
    function _transferFromTokenOwner(IERC20 token, address toAddress, uint256 amount) internal {
        // only works with Ownable token - need to override otherwise
        Ownable ownableToken = Ownable(address(token));

        _transferAndAssert(token, ownableToken.owner(), toAddress, amount);
    }

    /// @dev - transfer from the `fromAddress` to the `toAddress`
    function _transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
