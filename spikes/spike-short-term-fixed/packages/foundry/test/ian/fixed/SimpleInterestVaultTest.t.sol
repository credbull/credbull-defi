// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC4626Interest } from "@credbull-spike/contracts/ian/interfaces/IERC4626Interest.sol";
import { SimpleInterestVault } from "@credbull-spike/contracts/ian/fixed/SimpleInterestVault.sol";
import { Frequencies } from "@credbull-spike-test/ian/fixed/Frequencies.t.sol";

import { InterestTest } from "@credbull-spike-test/ian/fixed/InterestTest.t.sol";
import { ISimpleInterest } from "@credbull-spike/contracts/ian/interfaces/ISimpleInterest.sol";

import { SimpleUSDC } from "@credbull-spike/contracts/kk/SimpleUSDC.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SimpleInterestVaultTest is InterestTest {
  using Math for uint256;

  IERC20 private asset;

  address private owner = makeAddr("owner");
  address private alice = makeAddr("alice");
  address private bob = makeAddr("bob");

  function setUp() public {
    uint256 tokenSupply = 1000000 ether; // 1 million

    vm.startPrank(owner);
    asset = new SimpleUSDC(tokenSupply);
    vm.stopPrank();

    uint256 userTokenAmount = 100000 ether; // 100,000 each

    assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
    transferAndAssert(asset, owner, alice, userTokenAmount);
    transferAndAssert(asset, owner, bob, userTokenAmount);
  }

  function test__SimpleInterestVaultTest__CheckScale() public {
    uint256 apy = 10; // APY in percentage
    uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
    uint256 tenor = 90;

    IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

    uint256 scaleMinus1 = SCALE - 1;

    assertEq(0, vault.convertToAssets(scaleMinus1), "convert to assets not scaled");

    assertEq(0, vault.convertToShares(scaleMinus1), "convert to shares not scaled");
  }

  function test__SimpleInterestVaultTest__Monthly() public {
    uint256 apy = 12; // APY in percentage
    uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
    uint256 tenor = 3;

    IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

    testInterestToMaxPeriods(200 * SCALE, vault);
  }

  function test__SimpleInterestVaultTest__Daily360() public {
    uint256 apy = 10; // APY in percentage
    uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
    uint256 tenor = 90;

    IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

    testInterestToMaxPeriods(200 * SCALE, vault);
  }

  /*
    Scenario: Calculating returns for a standard investment
  Given a user has invested 50,000 USDC for exactly 30 days
  When the returns are calculated
  Then the user should receive 50,250 USDC (50,000 + 250 USDC interest, exactly 6.0% APY)
    */
  function test__SimpleInterestVaultTest__6APY_30day_50K() public {
    uint256 apy = 6; // APY in percentage
    uint256 tenor = 30;
    uint256 deposit = 50_000 * SCALE; // APY in percentage
    uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

    IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

    // verify interest
    uint256 actualInterest = vault.calcInterest(deposit, tenor);
    assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

    // verify full returns
    uint256 actualShares = vault.convertToShares(deposit);
    uint256 actualReturns = vault.convertToAssetsAtPeriod(actualShares, tenor);
    assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
  }

  /*
    Scenario: Calculating returns for a rolled-over investment
  Given a user has invested 40,000 USDC for 60 days (initial 30 days + 30 days rollover, 6% APY)
  When the returns are calculated
  Then the user should receive 40,600 USDC (40,000 + 401 USDC standard interest + 33.5 USDC rollover bonus)
    */
  function test__SimpleInterestVaultTest__6APY_30day_40K_and_Rollover() public {
    uint256 apy = 6; // APY in percentage
    uint256 tenor = 30;
    uint256 deposit = 50_000 * SCALE; // APY in percentage
    uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

    IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

    // verify interest
    uint256 actualInterest = vault.calcInterest(deposit, tenor);
    assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

    // verify full returns
    uint256 actualShares = vault.convertToShares(deposit);
    uint256 actualReturns = vault.convertToAssetsAtPeriod(actualShares, tenor);
    assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
  }

  function testInterestAtPeriod(
    uint256 principal,
    ISimpleInterest simpleInterest,
    uint256 numTimePeriods
  ) internal override {
    // test against the simple interest harness
    super.testInterestAtPeriod(principal, simpleInterest, numTimePeriods);

    // test the vault related
    IERC4626Interest vault = (IERC4626Interest)(address(simpleInterest));
    super.testConvertToAssetAndSharesAtPeriod(principal, vault, numTimePeriods); // previews only
    super.testDepositAndRedeemAtPeriod(owner, alice, principal, vault, numTimePeriods); // actual deposits/redeems
  }
}
