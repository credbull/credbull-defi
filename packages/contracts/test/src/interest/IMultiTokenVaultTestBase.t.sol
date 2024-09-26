// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Test } from "forge-std/Test.sol";

abstract contract IMultiTokenVaultTestBase is Test {
    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000010

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    struct IMultiTokenVaultTestParams {
        uint256 principal;
        uint256 depositPeriod;
        uint256 redeemPeriod;
    }

    // harness to test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtPeriods(IMultiTokenVault vault, uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
        internal
    {
        IMultiTokenVaultTestParams memory testParams = IMultiTokenVaultTestParams({
            principal: principal,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });

        return testVaultAtPeriods(vault, testParams);
    }

    // harness to test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtPeriods(IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams) internal {
        uint256[6] memory offsetNumPeriodsArr =
            [0, 1, 2, testParams.redeemPeriod - 1, testParams.redeemPeriod, testParams.redeemPeriod + 1];

        for (uint256 i = 0; i < offsetNumPeriodsArr.length; i++) {
            uint256 offsetNumPeriods = offsetNumPeriodsArr[i];

            IMultiTokenVaultTestParams memory testParamsWithOffset = IMultiTokenVaultTestParams({
                principal: testParams.principal,
                depositPeriod: testParams.depositPeriod + offsetNumPeriods,
                redeemPeriod: testParams.redeemPeriod + offsetNumPeriods
            });

            _testVaultAtPeriod(vault, testParamsWithOffset);
        }
    }

    function _testVaultAtPeriod(IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        returns (uint256 sharesAtPeriod, uint256 assetsAtPeriod)
    {
        testConvertToAssetAndSharesAtPeriod(vault, testParams); // previews only
        testPreviewDepositAndPreviewRedeem(vault, testParams); // previews only
        return testDepositAndRedeemAtPeriod(alice, vault, testParams); // actual deposits/redeems
    }

    // verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function testConvertToAssetAndSharesAtPeriod(IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentTimePeriodsElapsed(); // save previous state for later

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
        vault.setCurrentTimePeriodsElapsed(testParams.depositPeriod); // set deposit numPeriods
        uint256 actualShares = vault.convertToShares(testParams.principal);

        vault.setCurrentTimePeriodsElapsed(testParams.redeemPeriod); // set redeem numPeriods
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(actualShares, testParams.depositPeriod),
            TOLERANCE,
            _assertMsg("toShares/toAssets yield does not equal principal + interest", vault, testParams.depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state

        return (actualAssetsAtPeriod, actualAssetsAtPeriod);
    }

    // verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function testPreviewDepositAndPreviewRedeem(IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentTimePeriodsElapsed();

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        vault.setCurrentTimePeriodsElapsed(testParams.depositPeriod); // set deposit period prior to deposit
        actualSharesAtPeriod = vault.previewDeposit(testParams.principal);

        vault.setCurrentTimePeriodsElapsed(testParams.redeemPeriod); // warp to redeem / withdraw
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

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed);

        return (actualSharesAtPeriod, actualAssetsAtPeriod);
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositAndRedeemAtPeriod(
        address receiver,
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams
    ) internal virtual returns (uint256 actualSharesAtPeriod_, uint256 actualAssetsAtPeriod_) {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.currentTimePeriodsElapsed();
        uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

        // ------------------- deposit -------------------
        uint256 actualSharesAtPeriod = _testDepositOnly(receiver, vault, testParams);

        // ------------------- redeem -------------------
        uint256 actualAssetsAtPeriod =
            _testRedeemOnly(receiver, vault, testParams, actualSharesAtPeriod, prevReceiverAssetBalance);

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state

        return (actualSharesAtPeriod, actualAssetsAtPeriod);
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function _testDepositOnly(address receiver, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod_)
    {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.currentTimePeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.sharesAtPeriod(receiver, testParams.depositPeriod);

        // ------------------- deposit -------------------
        vault.setCurrentTimePeriodsElapsed(testParams.depositPeriod); // set deposit numPeriods
        vm.startPrank(receiver);
        assertGe(
            asset.balanceOf(receiver),
            testParams.principal,
            _assertMsg("not enough assets for deposit ", vault, testParams.depositPeriod)
        );
        asset.approve(address(vault), testParams.principal); // grant the vault allowance
        uint256 actualSharesAtPeriod = vault.deposit(testParams.principal, receiver); // now deposit
        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + actualSharesAtPeriod,
            vault.sharesAtPeriod(receiver, testParams.depositPeriod),
            _assertMsg("receiver did not receive the correct vault shares ", vault, testParams.depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed);

        return actualSharesAtPeriod;
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function _testRedeemOnly(
        address receiver,
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams,
        uint256 sharesToRedeemAtPeriod,
        uint256 prevReceiverAssetBalance // assetBalance before redeeming the latest deposit
    ) internal virtual returns (uint256 actualAssetsAtPeriod_) {
        IERC20 asset = IERC20(vault.asset());

        uint256 prevVaultPeriodsElapsed = vault.currentTimePeriodsElapsed();

        // ------------------- prep redeem -------------------
        uint256 expectedReturns = _expectedReturns(sharesToRedeemAtPeriod, vault, testParams);

        vm.startPrank(owner);
        _transferAndAssert(asset, owner, address(vault), expectedReturns); // fund the vault to cover redeem
        vm.stopPrank();

        // ------------------- redeem -------------------
        vault.setCurrentTimePeriodsElapsed(testParams.redeemPeriod); // warp the vault to redeem period

        vm.startPrank(receiver);
        uint256 actualAssetsAtPeriod =
            vault.redeemForDepositPeriod(sharesToRedeemAtPeriod, receiver, receiver, testParams.depositPeriod);
        vm.stopPrank();

        assertApproxEqAbs(
            testParams.principal + expectedReturns,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("assets does not equal principal + yield", vault, testParams.depositPeriod)
        );

        // verify the receiver has the USDC back
        assertApproxEqAbs(
            prevReceiverAssetBalance + expectedReturns,
            asset.balanceOf(receiver),
            TOLERANCE,
            _assertMsg("receiver did not receive the correct yield", vault, testParams.depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state

        return actualAssetsAtPeriod;
    }

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    function _expectedReturns(uint256 shares, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
        internal
        view
        virtual
        returns (uint256 expectedReturns_);

    function _assertMsg(string memory prefix, IMultiTokenVault vault, uint256 numPeriods)
        internal
        view
        returns (string memory)
    {
        string memory vaultToString = string.concat(" Vault address= ", vm.toString(address(vault)));

        (bool success, bytes memory result) = address(vault).staticcall(abi.encodeWithSignature("toString()"));

        if (success && result.length > 0) {
            // Decode the result if the call was successful
            vaultToString = string.concat(vaultToString, " ", abi.decode(result, (string)));
        }

        return string.concat(prefix, vaultToString, " timePeriod= ", vm.toString(numPeriods));
    }

    function _transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
