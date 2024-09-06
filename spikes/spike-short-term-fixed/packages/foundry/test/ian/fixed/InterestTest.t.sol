// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "@credbull-spike/contracts/ian/interfaces/ISimpleInterest.sol";
import { IERC4626Interest } from "@credbull-spike/contracts/ian/interfaces/IERC4626Interest.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";


abstract contract InterestTest is Test {
  uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005
  uint256 public constant NUM_CYCLES_TO_TEST = 2; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

  using Math for uint256;

  function testInterestToMaxPeriods(uint256 principal, ISimpleInterest simpleInterest) internal {
    uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days

    // due to small fractional numbers, principal needs to be SCALED to calculate correctly
    assertGe(principal, simpleInterest.getScale(), "principal not in SCALE");

    // check all periods for 24 months
    for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
      testInterestAtPeriod(principal, simpleInterest, numTimePeriods);
    }
  }

  function testInterestAtPeriod(
    uint256 principal,
    ISimpleInterest simpleInterest,
    uint256 numTimePeriods
  ) internal virtual {
    // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
    //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

    uint256 discounted = simpleInterest.calcDiscounted(principal, numTimePeriods);
    uint256 principalFromDiscounted = simpleInterest.calcPrincipalFromDiscounted(discounted, numTimePeriods);

    assertApproxEqAbs(
      principal,
      principalFromDiscounted,
      TOLERANCE,
      assertMsg("principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
    );

    // verify for partial - does it hold that X% of principalFromDiscounted = X% principal
    uint256 discountedPartial = simpleInterest.calcDiscounted(principal.mulDiv(75, 100), numTimePeriods);
    uint256 principalFromDiscountedPartial =
      simpleInterest.calcPrincipalFromDiscounted(discountedPartial, numTimePeriods);

    assertApproxEqAbs(
      principal.mulDiv(75, 100),
      principalFromDiscountedPartial,
      TOLERANCE,
      assertMsg("partial principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
    );
  }


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
    uint256 expectedYield = principal + vault.calcInterest(principal, vault.getTenor());

    vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit period prior to deposit
    uint256 actualSharesDeposit = vault.previewDeposit(principal);

    vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // warp to redeem / withdraw

    // check previewRedeem
    assertApproxEqAbs(
      expectedYield,
      vault.previewRedeem(actualSharesDeposit),
      TOLERANCE,
      assertMsg("previewDeposit/previewRedeem yield does not equal principal + interest", vault, numTimePeriods)
    );

    // check previewWithdraw (uses assets as basis of assets returned)
    // should be the same as convertToShares
    uint256 actualSharesConvertToShares = vault.convertToSharesAtPeriod(expectedYield, numTimePeriods);
    uint256 actualSharesPreviewWithdraw = vault.previewWithdraw(expectedYield);
    assertEq(actualSharesPreviewWithdraw, actualSharesConvertToShares, assertMsg("previewWithdraw should equal convertToShares", vault, numTimePeriods));

    vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
  }

  // verify deposit and redeem.  These update vault assets and shares.
  function testDepositAndRedeemAtPeriod(
    address owner,
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
    vm.startPrank(owner);
    transferAndAssert(asset, owner, address(vault), interest);
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

  function assertMsg(
    string memory prefix,
    ISimpleInterest simpleInterest,
    uint256 numTimePeriods
  ) internal view returns (string memory) {
    return string.concat(prefix, toString(simpleInterest), " timePeriod= ", vm.toString(numTimePeriods));
  }

  function toString(ISimpleInterest simpleInterest) internal view returns (string memory) {
    return string.concat(
      " ISimpleInterest [ ",
      " IR = ",
      vm.toString(simpleInterest.getInterestInPercentage()),
      " Freq = ",
      vm.toString(simpleInterest.getFrequency()),
      " ] "
    );
  }

  function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
    uint256 beforeBalance = _token.balanceOf(toAddress);

    vm.startPrank(fromAddress);
    _token.transfer(toAddress, amount);
    vm.stopPrank();

    assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
  }
}
