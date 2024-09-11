// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ICalcInterest } from "@credbull-spike/contracts/ian/interfaces/ICalcInterest.sol";
import { ICalcDiscounted } from "@credbull-spike/contracts/ian/interfaces/ICalcDiscounted.sol";
import { IERC4626Interest } from "@credbull-spike/contracts/ian/interfaces/IERC4626Interest.sol";
import { ICalcInterestMetadata } from "@credbull-spike/contracts/ian/interfaces/ICalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { CalcDiscountedTestBase } from "@credbull-spike-test/ian/fixed/CalcDiscountedTestBase.t.sol";

abstract contract InterestVaultTest is CalcDiscountedTestBase {
  using Math for uint256;

  address internal owner = makeAddr("owner");
  address internal alice = makeAddr("alice");
  address internal bob = makeAddr("bob");

  // verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
  function testConvertToAssetAndSharesAtPeriod(
    uint256 principal,
    IERC4626Interest vault,
    uint256 numTimePeriods
  ) internal virtual {
    // ------------------- check toShares/toAssets - specified period -------------------
    uint256 expectedYield = principal + vault.calcInterest(principal, vault.getTenor()); // yield = principal + interest

    uint256 sharesAtPeriod = vault.convertToSharesAtPeriod(principal, numTimePeriods);
    uint256 assetsAtPeriod = vault.convertToAssetsAtPeriod(sharesAtPeriod, numTimePeriods + vault.getTenor());

    assertApproxEqAbs(
      expectedYield,
      assetsAtPeriod,
      TOLERANCE,
      assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
    );

    // ------------------- check toShares/toAssets - current period -------------------
    uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed(); // save previous state for later

    vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
    uint256 actualShares = vault.convertToShares(principal);

    vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // set redeem numTimePeriods
    uint256 actualAssets = vault.convertToAssets(actualShares); // now redeem

    assertApproxEqAbs(
      principal + vault.calcInterest(principal, vault.getTenor()),
      actualAssets,
      TOLERANCE,
      assertMsg("toShares/toAssets yield does not equal principal + interest", vault, numTimePeriods)
    );

    // ------------------- check partials  -------------------
    uint256 expectedPartialYield =
      principal.mulDiv(33, 100) + vault.calcInterest(principal.mulDiv(33, 100), vault.getTenor());

    uint256 partialAssetsAtPeriod =
      vault.convertToAssetsAtPeriod(actualShares.mulDiv(33, 100), numTimePeriods + vault.getTenor());

    assertApproxEqAbs(
      expectedPartialYield,
      partialAssetsAtPeriod,
      TOLERANCE,
      assertMsg("partial yield does not equal principal + interest", vault, numTimePeriods)
    );

    vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
  }

  // verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
  function testPreviewDepositAndPreviewRedeem(
    uint256 principal,
    IERC4626Interest vault,
    uint256 numTimePeriods
  ) internal virtual {
    uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
    uint256 expectedInterest = vault.calcInterest(principal, vault.getTenor());
    uint256 expectedPrincipalAndInterest = principal + expectedInterest;

    vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit period prior to deposit
    uint256 actualSharesDeposit = vault.previewDeposit(principal);

    vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // warp to redeem / withdraw

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
    assertEq(
      vault.previewWithdraw(expectedInterest),
      vault.convertToSharesAtPeriod(expectedInterest, numTimePeriods),
      assertMsg("previewWithdraw incorrect - interest", vault, numTimePeriods)
    );

    vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed);
  }

  // verify deposit and redeem.  These update vault assets and shares.
  function testDepositAndRedeemAtPeriod(
    address _owner,
    address receiver,
    uint256 principal,
    IERC4626Interest vault,
    uint256 numTimePeriods
  ) internal virtual {
    IERC20 asset = IERC20(vault.asset());

    // capture state before for validations
    uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
    uint256 prevReceiverVaultBalance = vault.balanceOf(receiver);
    uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

    // deposit
    vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
    vm.startPrank(receiver);
    assertGe(asset.balanceOf(receiver), principal, assertMsg("not enough assets for deposit ", vault, numTimePeriods));
    asset.approve(address(vault), principal); // grant the vault allowance
    uint256 shares = vault.deposit(principal, receiver); // now deposit
    vm.stopPrank();
    assertEq(
      prevReceiverVaultBalance + shares,
      vault.balanceOf(receiver),
      assertMsg("receiver did not receive the correct vault shares ", vault, numTimePeriods)
    );

    // give the vault enough to cover the earned interest

    uint256 interest = vault.calcInterest(principal, vault.getTenor());
    vm.startPrank(_owner);
    transferAndAssert(asset, _owner, address(vault), interest);
    vm.stopPrank();

    // redeem
    vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // warp the vault to redeem period

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

    vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
  }

  function testInterestAtPeriod(
    uint256 principal,
    ICalcInterestMetadata simpleInterest,
    uint256 numTimePeriods
  ) internal override {
    // test the vault related
    IERC4626Interest vault = (IERC4626Interest)(address(simpleInterest));

    // test against the simple interest harness
    super.testInterestAtPeriod(principal, vault, numTimePeriods);

    testConvertToAssetAndSharesAtPeriod(principal, vault, numTimePeriods); // previews only
    testPreviewDepositAndPreviewRedeem(principal, vault, numTimePeriods); // previews only
    testDepositAndRedeemAtPeriod(owner, alice, principal, vault, numTimePeriods); // actual deposits/redeems
  }

  function testInterestForTenor(uint256 principal, IERC4626Interest vault) internal {
    testInterestAtPeriod(principal, vault, vault.getTenor());
  }

  function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
    uint256 beforeBalance = _token.balanceOf(toAddress);

    vm.startPrank(fromAddress);
    _token.transfer(toAddress, amount);
    vm.stopPrank();

    assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
  }
}
