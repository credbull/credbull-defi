// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IDiscountVault } from "@credbull/token/ERC4626/IDiscountVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { DiscountVault } from "../../../../src/token/ERC4626/DiscountVault.sol";

abstract contract DiscountVaultTestBase is Test {
    using Math for uint256;

    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function testVaultAtTenorPeriods(uint256 principal, IDiscountVault vault) internal {
        uint256 tenor = vault.getTenor();

        uint256[5] memory numTimePeriodsElapsedArr = [0, 1, tenor - 1, tenor, tenor + 1];

        // Iterate through the lock periods and calculate the principal for each
        for (uint256 i = 0; i < numTimePeriodsElapsedArr.length; i++) {
            uint256 numTimePeriodsElapsed = numTimePeriodsElapsedArr[i];

            testVaultAtPeriod(principal, vault, numTimePeriodsElapsed);
        }
    }

    function testVaultAtPeriod(uint256 principal, IDiscountVault vault, uint256 numTimePeriods) internal {
        testConvertToAssetAndSharesAtPeriod(principal, vault, numTimePeriods); // previews only
        testPreviewDepositAndPreviewRedeem(principal, vault, numTimePeriods); // previews only
        testDepositAndRedeemAtPeriod(owner, alice, principal, vault, numTimePeriods); // actual deposits/redeems
    }

    // verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function testConvertToAssetAndSharesAtPeriod(uint256 principal, IDiscountVault vault, uint256 numTimePeriods)
        internal
        virtual
    {
        // ------------------- check toShares/toAssets - current period -------------------
        uint256 prevVaultTimePeriodsElapsed = vault.currentPeriodsElapsed(); // save previous state for later

        _warpToPeriod(vault, numTimePeriods); // set deposit numTimePeriods
        uint256 actualShares = vault.convertToShares(principal);

        _warpToPeriod(vault, numTimePeriods + vault.getTenor()); // set redeem numTimePeriods
        uint256 actualAssets = vault.convertToAssets(actualShares); // now redeem

        assertApproxEqAbs(
            principal + _expectedReturnsFullTenor(principal, vault),
            actualAssets,
            TOLERANCE,
            assertMsg("toShares/toAssets yield does not equal principal + interest", vault, numTimePeriods)
        );

        // ------------------- check partials  -------------------
        uint256 expectedPartialYield =
            principal.mulDiv(33, 100) + _expectedReturnsFullTenor(principal.mulDiv(33, 100), vault);

        _warpToPeriod(vault, numTimePeriods + vault.getTenor()); // set redeem numTimePeriods

        uint256 partialAssetsAtPeriod = vault.convertToAssets(actualShares.mulDiv(33, 100));

        assertApproxEqAbs(
            expectedPartialYield,
            partialAssetsAtPeriod,
            TOLERANCE,
            assertMsg("partial yield does not equal principal + interest", vault, numTimePeriods)
        );

        _warpToPeriod(vault, prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    // verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function testPreviewDepositAndPreviewRedeem(uint256 principal, IDiscountVault vault, uint256 numTimePeriods)
        internal
        virtual
    {
        uint256 prevVaultTimePeriodsElapsed = vault.currentPeriodsElapsed();
        uint256 expectedInterest = _expectedReturnsFullTenor(principal, vault);
        uint256 expectedPrincipalAndInterest = principal + expectedInterest;

        _warpToPeriod(vault, numTimePeriods); // set deposit period prior to deposit
        uint256 actualSharesDeposit = vault.previewDeposit(principal);

        _warpToPeriod(vault, numTimePeriods + vault.getTenor()); // warp to redeem / withdraw

        // check previewRedeem
        assertApproxEqAbs(
            expectedPrincipalAndInterest,
            vault.previewRedeem(actualSharesDeposit),
            TOLERANCE,
            assertMsg("previewDeposit/previewRedeem yield does not equal principal + interest", vault, numTimePeriods)
        );

        // check previewWithdraw (uses assets as basis of shares returned)
        // as per definition - should be the same as convertToShares
        assertEq(
            vault.previewWithdraw(principal),
            actualSharesDeposit,
            assertMsg("previewWithdraw incorrect - principal", vault, numTimePeriods)
        );

        _warpToPeriod(vault, prevVaultTimePeriodsElapsed);
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositAndRedeemAtPeriod(
        address _owner,
        address receiver,
        uint256 principal,
        IDiscountVault vault,
        uint256 numTimePeriods
    ) internal virtual {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultTimePeriodsElapsed = vault.currentPeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.balanceOf(receiver);
        uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

        // deposit
        _warpToPeriod(vault, numTimePeriods); // set deposit numTimePeriods
        vm.startPrank(receiver);
        assertGe(
            asset.balanceOf(receiver), principal, assertMsg("not enough assets for deposit ", vault, numTimePeriods)
        );
        asset.approve(address(vault), principal); // grant the vault allowance
        uint256 shares = vault.deposit(principal, receiver); // now deposit

        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + shares,
            vault.balanceOf(receiver),
            assertMsg("receiver did not receive the correct vault shares ", vault, numTimePeriods)
        );

        // give the vault enough to cover the earned interest

        uint256 interest = _expectedReturnsFullTenor(principal, vault);
        vm.startPrank(_owner);
        transferAndAssert(asset, _owner, address(vault), interest);
        vm.stopPrank();

        // redeem
        _warpToPeriod(vault, numTimePeriods + vault.getTenor()); // warp the vault to redeem period

        vm.startPrank(receiver);
        uint256 assets = vault.redeem(shares, receiver, receiver);
        vm.stopPrank();
        assertApproxEqAbs(
            prevReceiverAssetBalance + interest,
            asset.balanceOf(receiver),
            TOLERANCE,
            assertMsg("receiver did not receive the correct yield", vault, numTimePeriods)
        );

        assertApproxEqAbs(
            principal + interest,
            assets,
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
        );

        _warpToPeriod(vault, prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    function _warpToPeriod(IDiscountVault vault, uint256 timePeriod) internal virtual {
        DiscountVault discountVault = DiscountVault(address(vault));

        uint256 warpToTimeInSeconds = discountVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }

    function _expectedReturnsFullTenor(uint256 principal, IDiscountVault vault)
        internal
        view
        returns (uint256 expectedReturns_)
    {
        return _expectedReturns(principal, vault, 0, vault.getTenor());
    }

    function _expectedReturns(uint256 principal, IDiscountVault vault, uint256 fromPeriod, uint256 toPeriod)
        internal
        view
        returns (uint256 expectedReturns_)
    {
        DiscountVault discountVault = DiscountVault(address(vault));

        return discountVault.YIELD_STRATEGY().calcYield(address(vault), principal, fromPeriod, toPeriod);
    }

    function assertMsg(string memory prefix, IDiscountVault vault, uint256 numTimePeriods)
        internal
        view
        returns (string memory)
    {
        return string.concat(prefix, vm.toString(address(vault)), " timePeriod= ", vm.toString(numTimePeriods));
    }

    function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
