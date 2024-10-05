// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { Test } from "forge-std/Test.sol";

abstract contract IMultiTokenVaultTestBase is Test {
    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000010

    struct IMultiTokenVaultTestParams {
        uint256 principal;
        uint256 depositPeriod;
        uint256 redeemPeriod;
    }

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtPeriods(
        address account,
        IMultiTokenVault vault,
        uint256 principal,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) internal {
        IMultiTokenVaultTestParams memory testParams = IMultiTokenVaultTestParams({
            principal: principal,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });

        return testVaultAtPeriods(account, vault, testParams);
    }

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtPeriods(address account, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
    {
        uint256[6] memory offsetNumPeriodsArr =
            [0, 1, 2, testParams.redeemPeriod - 1, testParams.redeemPeriod, testParams.redeemPeriod + 1];

        for (uint256 i = 0; i < offsetNumPeriodsArr.length; i++) {
            uint256 offsetNumPeriods = offsetNumPeriodsArr[i];

            IMultiTokenVaultTestParams memory testParamsWithOffset = IMultiTokenVaultTestParams({
                principal: testParams.principal,
                depositPeriod: testParams.depositPeriod + offsetNumPeriods,
                redeemPeriod: testParams.redeemPeriod + offsetNumPeriods
            });

            _testVaultAtPeriod(account, vault, testParamsWithOffset);
        }
    }

    /// @dev test the vault at the given test parameters
    function _testVaultAtPeriod(address account, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        returns (uint256 sharesAtPeriod, uint256 assetsAtPeriod)
    {
        testConvertToAssetAndSharesAtPeriod(vault, testParams); // previews only, account agnostic
        testPreviewDepositAndPreviewRedeem(vault, testParams); // previews only, account agnostic
        return testDepositAndRedeemAtPeriod(account, vault, testParams); // actual deposits/redeems
    }

    /// @dev performance / load test harness to execute a number of deposits first, and then redeem after
    function _loadTestVault(IMultiTokenVault vault, uint256 principal, uint256 fromPeriod, uint256 toPeriod) internal {
        address charlie = makeAddr("charlie");
        address david = makeAddr("david");

        IERC20Metadata _asset = IERC20Metadata(vault.asset());
        uint256 _scale = 10 ** _asset.decimals();

        _transferFromTokenOwner(_asset, charlie, 1_000_000_000 * _scale);
        _transferFromTokenOwner(_asset, david, 1_000_000_000 * _scale);

        // "wastes" storage from 0 -> fromPeriod.  but fine in test, and makes the depositPeriod clear
        uint256[] memory charlieShares = new uint256[](toPeriod + 1);
        uint256[] memory davidShares = new uint256[](toPeriod + 1);

        // ----------------------- deposits -----------------------
        for (uint256 i = fromPeriod; i < toPeriod; ++i) {
            IMultiTokenVaultTestParams memory depositTestParams = IMultiTokenVaultTestParams({
                principal: principal,
                depositPeriod: i,
                redeemPeriod: 0 // not used in deposit flow
             });
            charlieShares[i] = _testDepositOnly(charlie, vault, depositTestParams);
            davidShares[i] = _testDepositOnly(david, vault, depositTestParams);
        }

        // ----------------------- redeems -----------------------
        for (uint256 i = fromPeriod; i < toPeriod; ++i) {
            IMultiTokenVaultTestParams memory redeemTestParams =
                IMultiTokenVaultTestParams({ principal: principal, depositPeriod: i, redeemPeriod: toPeriod });

            _testRedeemOnly(charlie, vault, redeemTestParams, charlieShares[i]);
            _testRedeemOnly(david, vault, redeemTestParams, davidShares[i]);
        }
    }

    /// @dev verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function testConvertToAssetAndSharesAtPeriod(IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed(); // save previous state for later

        // ------------------- check toShares/toAssets - specified period -------------------
        actualSharesAtPeriod = vault.convertToSharesForDepositPeriod(testParams.principal, testParams.depositPeriod);
        actualAssetsAtPeriod = vault.convertToAssetsForDepositPeriod(
            actualSharesAtPeriod, testParams.depositPeriod, testParams.redeemPeriod
        );

        uint256 expectedAssetsAtRedeem =
            testParams.principal + _expectedReturns(actualSharesAtPeriod, vault, testParams);

        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("yield does not equal principal + interest", vault, testParams.depositPeriod)
        );

        // ------------------- check toShares/toAssets - current period -------------------
        _warpToPeriod(vault, testParams.depositPeriod); // warp to deposit
        uint256 actualShares = vault.convertToShares(testParams.principal);

        _warpToPeriod(vault, testParams.redeemPeriod); // warp to redeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(actualShares, testParams.depositPeriod),
            TOLERANCE,
            _assertMsg("toShares/toAssets yield does not equal principal + interest", vault, testParams.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore to previous state

        return (actualAssetsAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function testPreviewDepositAndPreviewRedeem(IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        _warpToPeriod(vault, testParams.depositPeriod); // warp to deposit
        actualSharesAtPeriod = vault.previewDeposit(testParams.principal);

        _warpToPeriod(vault, testParams.redeemPeriod); // warp to redeem / withdraw
        actualAssetsAtPeriod = vault.previewRedeemForDepositPeriod(actualSharesAtPeriod, testParams.depositPeriod);

        uint256 expectedAssetsAtRedeem =
            testParams.principal + _expectedReturns(actualSharesAtPeriod, vault, testParams);

        // check previewRedeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.previewRedeemForDepositPeriod(actualSharesAtPeriod, testParams.depositPeriod),
            TOLERANCE,
            _assertMsg(
                "previewDeposit/previewRedeem yield does not equal principal + interest",
                vault,
                testParams.depositPeriod
            )
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return (actualSharesAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev verify deposit and redeem.  These update vault assets and shares.
    function testDepositAndRedeemAtPeriod(
        address account,
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams
    ) internal virtual returns (uint256 actualSharesAtPeriod_, uint256 actualAssetsAtPeriod_) {
        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- deposit -------------------
        uint256 actualSharesAtPeriod = _testDepositOnly(account, vault, testParams);

        // ------------------- redeem -------------------
        uint256 actualAssetsAtPeriod = _testRedeemOnly(account, vault, testParams, actualSharesAtPeriod);

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return (actualSharesAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev verify deposit.  updates vault assets and shares.
    function _testDepositOnly(address account, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod_)
    {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.sharesAtPeriod(account, testParams.depositPeriod);

        // ------------------- deposit -------------------
        _warpToPeriod(vault, testParams.depositPeriod); // warp to deposit period

        vm.startPrank(account);
        assertGe(
            asset.balanceOf(account),
            testParams.principal,
            _assertMsg("not enough assets for deposit ", vault, testParams.depositPeriod)
        );
        asset.approve(address(vault), testParams.principal); // grant the vault allowance
        uint256 actualSharesAtPeriod = vault.deposit(testParams.principal, account); // now deposit
        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.sharesAtPeriod(account, testParams.depositPeriod),
            _assertMsg(
                "receiver did not receive the correct vault shares - sharesAtPeriod", vault, testParams.depositPeriod
            )
        );
        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.sharesAtPeriod(account, testParams.depositPeriod),
            _assertMsg(
                "receiver did not receive the correct vault shares - balanceOf ", vault, testParams.depositPeriod
            )
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return actualSharesAtPeriod;
    }

    /// @dev verify redeem.  updates vault assets and shares.
    function _testRedeemOnly(
        address account,
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual returns (uint256 actualAssetsAtPeriod_) {
        IERC20 asset = IERC20(vault.asset());

        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- prep redeem -------------------
        uint256 assetBalanceBeforeRedeem = asset.balanceOf(account);
        uint256 expectedReturns = _expectedReturns(sharesToRedeemAtPeriod, vault, testParams);

        _transferFromTokenOwner(asset, address(vault), expectedReturns);

        // ------------------- redeem -------------------
        _warpToPeriod(vault, testParams.redeemPeriod); // warp the vault to redeem period

        vm.startPrank(account);
        uint256 actualAssetsAtPeriod =
            vault.redeemForDepositPeriod(sharesToRedeemAtPeriod, account, account, testParams.depositPeriod);
        vm.stopPrank();

        assertApproxEqAbs(
            testParams.principal + expectedReturns,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("assets does not equal principal + yield", vault, testParams.depositPeriod)
        );

        // verify the receiver has the USDC back
        assertApproxEqAbs(
            assetBalanceBeforeRedeem + testParams.principal + expectedReturns,
            asset.balanceOf(account),
            TOLERANCE,
            _assertMsg("receiver did not receive the correct yield", vault, testParams.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore the vault to previous state

        return actualAssetsAtPeriod;
    }

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    function _expectedReturns(uint256 shares, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        view
        virtual
        returns (uint256 expectedReturns_);

    /// @dev warp the vault to the given timePeriod for testing purposes
    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IMultiTokenVault, /* vault */ uint256 timePeriod) internal virtual {
        vm.warp(Timer.timestamp() + timePeriod * 24 hours);
    }

    /// @dev - creates a IMultiTokenVaultTestParams for testing
    function _createTestParams(uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
        internal
        pure
        returns (IMultiTokenVaultTestParams memory testParams)
    {
        return IMultiTokenVaultTestParams({
            principal: principal,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });
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
