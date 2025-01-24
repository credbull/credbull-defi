// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";
import { TestUtil } from "@test/test/util/TestUtil.t.sol";
import { IVaultVerifier } from "@test/test/token/ERC4626/IVaultVerifier.t.sol";

import { Test } from "forge-std/Test.sol";

abstract contract IVaultVerifierBase is IVaultVerifier, Test, TestUtil {
    using TestParamSet for TestParamSet.TestParam[];

    /// @dev test the vault at the given test parameters
    function verifyVault(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam[] memory testParams
    ) public virtual returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_) {
        // capture vault state before warping around
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- deposits w/ redeems per deposit -------------------
        // NB - test all of the deposits BEFORE redeems.  verifies no side-effects from deposits when redeeming.
        uint256[] memory sharesAtPeriods = _verifyDepositOnly(depositUsers, vault, testParams);

        // NB - test all of the redeems AFTER deposits.  verifies no side-effects from deposits when redeeming.
        uint256[] memory assetsAtPeriods = _verifyRedeemOnly(redeemUsers, vault, testParams, sharesAtPeriods);

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return (sharesAtPeriods, assetsAtPeriods);
    }

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function verifyVaultAtOffsets(address account, IVault vault, TestParamSet.TestParam memory testParam)
        public
        virtual
        returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_)
    {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _createTestUsers(account);

        return verifyVaultAtOffsets(depositUsers, redeemUsers, vault, testParam);
    }

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function verifyVaultAtOffsets(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) internal virtual returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_) {
        TestParamSet.TestParam[] memory testParams = TestParamSet.toOffsetArray(testParam);
        return verifyVault(depositUsers, redeemUsers, vault, testParams);
    }

    /// @dev verify deposit.  updates vault assets and shares.
    function _verifyDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IVault vault,
        TestParamSet.TestParam[] memory testParams
    ) public virtual returns (uint256[] memory sharesAtPeriod_) {
        uint256[] memory sharesAtPeriod = new uint256[](testParams.length);
        for (uint256 i = 0; i < testParams.length; i++) {
            sharesAtPeriod[i] = _verifyDepositOnly(depositUsers, vault, testParams[i]);
        }
        return sharesAtPeriod;
    }

    /// @dev verify deposit.  updates vault assets and shares.
    function _verifyDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) public virtual returns (uint256 actualSharesAtPeriod_) {
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
            _expectedShares(vault, testParam),
            actualSharesAtPeriod,
            _assertMsg("deposit shares don't match expected shares", vault, testParam.depositPeriod)
        );
        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.sharesAtPeriod(depositUsers.tokenReceiver, testParam.depositPeriod),
            _assertMsg(
                "receiver did not receive the correct vault shares - sharesAtPeriod", vault, testParam.depositPeriod
            )
        );
        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.sharesAtPeriod(depositUsers.tokenReceiver, testParam.depositPeriod),
            _assertMsg("receiver did not receive the correct vault shares - balanceOf ", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return actualSharesAtPeriod;
    }

    /// @dev verify redeem.  updates vault assets and shares.
    function _verifyRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam[] memory testParams,
        uint256[] memory sharesAtPeriods
    ) public virtual returns (uint256[] memory assetsAtPeriods_) {
        uint256[] memory assetsAtPeriods = new uint256[](testParams.length);
        for (uint256 i = 0; i < testParams.length; i++) {
            assetsAtPeriods[i] = _verifyRedeemOnly(redeemUsers, vault, testParams[i], sharesAtPeriods[i]);
        }
        return assetsAtPeriods;
    }

    /// @dev verify redeem.  updates vault assets and shares.
    function _verifyRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) public virtual returns (uint256 actualAssetsAtPeriod_) {
        IERC20 asset = IERC20(vault.asset());

        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- prep redeem -------------------
        uint256 assetBalanceBeforeRedeem = asset.balanceOf(redeemUsers.tokenReceiver);
        uint256 shareBalanceBeforeRedeem = vault.sharesAtPeriod(redeemUsers.tokenOwner, testParam.depositPeriod);
        uint256 expectedAssets = _expectedAssets(vault, testParam);

        _transferFromTokenOwner(asset, address(vault), expectedAssets);

        // ------------------- redeem -------------------
        _warpToPeriod(vault, testParam.redeemPeriod); // warp the vault to redeem period

        // authorize the tokenOperator
        _approveForAll(vault, redeemUsers.tokenOwner, redeemUsers.tokenOperator, true);

        vm.startPrank(redeemUsers.tokenOperator);
        uint256 actualAssetsAtPeriod = vault.redeemForDepositPeriod(
            sharesToRedeemAtPeriod, redeemUsers.tokenReceiver, redeemUsers.tokenOwner, testParam.depositPeriod
        );
        vm.stopPrank();

        // de-authorize the tokenOperator
        _approveForAll(vault, redeemUsers.tokenOwner, redeemUsers.tokenOperator, false);

        assertApproxEqAbs(
            expectedAssets,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("assets does not equal principal + yield", vault, testParam.depositPeriod)
        );

        // verify the token owner shares reduced
        assertEq(
            shareBalanceBeforeRedeem - sharesToRedeemAtPeriod,
            vault.sharesAtPeriod(redeemUsers.tokenOwner, testParam.depositPeriod),
            _assertMsg("shares not reduced by redeem amount", vault, testParam.depositPeriod)
        );

        // verify the receiver has the USDC back
        assertApproxEqAbs(
            assetBalanceBeforeRedeem + expectedAssets,
            asset.balanceOf(redeemUsers.tokenReceiver),
            TOLERANCE,
            _assertMsg("receiver did not receive the correct yield", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore the vault to previous state

        return actualAssetsAtPeriod;
    }

    // ===================== Test Utilities =====================

    /// @dev - creates a collection of test users to exercise access control
    function _createTestUsers(address account)
        public
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

        //    return (depositUsers, redeemUsers);

        TestParamSet.TestUsers memory redeemUsersOperatorIsOwner = TestParamSet.TestUsers({
            tokenOwner: redeemUsers.tokenOwner,
            tokenReceiver: redeemUsers.tokenReceiver,
            tokenOperator: redeemUsers.tokenOwner
        });

        return (depositUsers, redeemUsersOperatorIsOwner);
    }

    /// @dev warp the vault to the given timePeriod for testing purposes
    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IVault, /* vault */ uint256 timePeriod) public virtual {
        vm.warp(Timer.timestamp() + timePeriod * 24 hours);
    }

    /// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
    // // TODO - set(remove) the max allowance for the operator
    function _approveForAll(IVault vault, address owner, address operator, bool approved) internal virtual;

    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        virtual
        returns (uint256 expectedShares);

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    // NB - this uses the testParam principal (rather than using the shares)
    function _expectedAssets(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        virtual
        returns (uint256 expectedReturns_)
    {
        return testParam.principal + _expectedReturns(vault, testParam);
    }

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    // NB - this uses the testParam principal (rather than using the shares)
    function _expectedReturns(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        virtual
        returns (uint256 expectedReturns_);

    // ===================== Other Utility =====================

    /// @dev - creates a message string for assertions
    function _assertMsg(string memory prefix, IVault vault, uint256 numPeriods) internal pure returns (string memory) {
        return string.concat(prefix, " Vault= ", vm.toString(address(vault)), " timePeriod= ", vm.toString(numPeriods));
    }
}
