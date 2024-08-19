// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";
import { Tenors } from "./Tenors.s.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

contract SimpleInterestVaultTest is Test {
    using Math for uint256;

    IERC20 private asset;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");

    uint256 public constant TOLERANCE = 100; // with 18 decimals, means allowed difference of 1E+16

    function setUp() public {
        uint256 tokenSupply = 100000 ether;

        vm.startPrank(owner);
        asset = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 1000 ether;

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, alice, userTokenAmount);
        transferAndAssert(asset, bob, userTokenAmount);
        transferAndAssert(asset, charlie, userTokenAmount);
    }

    function test__SimpleInterestVault__Daily_0_1_2() public {
        uint256 apy = 10; // APY in percentage, e.g. 12%
        Tenors.Tenor tenorDays365 = Tenors.Tenor.DAYS_365;

        Deposit memory depositAlice = Deposit("alice 0 days", alice, 100 ether, 0);
        Deposit memory depositBob = Deposit("bob 2 day", bob, 100 ether, 1);
        Deposit memory depositCharlie = Deposit("charlie 3 days", charlie, 100 ether, 2);

        verifySimpleInterestVault(apy, tenorDays365, depositAlice, depositBob, depositCharlie);
    }

    // represents the second cycle - days 30, 31, 32 (equiv to 1,2,3)
    function test__SimpleInterestVault__Daily_30_31_32() public {
        uint256 apy = 10; // APY in percentage, e.g. 12%
        Tenors.Tenor tenorDays365 = Tenors.Tenor.DAYS_365;

        Deposit memory depositAlice = Deposit("alice 30 days", alice, 100 ether, 30);
        Deposit memory depositBob = Deposit("bob 31 days", bob, 100 ether, 31); // 365 / 5 = 73
        Deposit memory depositCharlie = Deposit("charlie 32 days", charlie, 100 ether, 32);

        verifySimpleInterestVault(apy, tenorDays365, depositAlice, depositBob, depositCharlie);
    }

    // represents the second cycle - days 30, 31, 32 (equiv to 1,2,3)
    function test__SimpleInterestVault__Daily_10_20_29() public {
        uint256 apy = 10; // APY in percentage, e.g. 12%
        Tenors.Tenor tenorDays365 = Tenors.Tenor.DAYS_365;

        Deposit memory depositAlice = Deposit("alice 10 days", alice, 100 ether, 10);
        Deposit memory depositBob = Deposit("bob 20 days", bob, 100 ether, 20); // 365 / 5 = 73
        Deposit memory depositCharlie = Deposit("charlie 29 days", charlie, 100 ether, 29);

        verifySimpleInterestVault(apy, tenorDays365, depositAlice, depositBob, depositCharlie);
    }

    struct Deposit {
        string name;
        address wallet;
        uint256 amountInWei;
        // vault state at time of deposit
        uint256 numTimePeriodsElapsedAtDeposit;
    }

    function verifySimpleInterestVault(
        uint256 apy,
        Tenors.Tenor frequency,
        Deposit memory depositAlice,
        Deposit memory depositBob,
        Deposit memory depositCharlie
    ) internal {
        // set up vault
        SimpleInterest simpleInterest = new SimpleInterest(apy, frequency);
        SimpleInterestVault vault = new SimpleInterestVault(asset, simpleInterest);

        uint256 sharesInWeiAlice = depositAndVerify(depositAlice, vault);
        uint256 sharesInWeiBob = depositAndVerify(depositBob, vault);
        uint256 sharesInWeiCharlie = depositAndVerify(depositCharlie, vault);

        // ============== redeem ==============
        console2.log("================ start redeem ==============");

        // verify the previewRedeem and convertToAsset (these don't actually redeem) - cycle 1 (no roll-over)
        previewRedeemAndVerify(depositAlice, sharesInWeiAlice, vault);
        previewRedeemAndVerify(depositBob, sharesInWeiBob, vault);
        previewRedeemAndVerify(depositCharlie, sharesInWeiCharlie, vault);

        // add enough interest to cover all redeems
        vm.startPrank(owner);
        asset.transfer(address(vault), (depositAlice.amountInWei + depositBob.amountInWei + depositCharlie.amountInWei)); // enough for 100% interest
        vm.stopPrank();

        // now actually redeem - exchange shares back for assets
        redeemAndVerify(depositAlice, sharesInWeiAlice, vault);
        redeemAndVerify(depositBob, sharesInWeiBob, vault);
        redeemAndVerify(depositCharlie, sharesInWeiCharlie, vault);
    }

    function depositAndVerify(Deposit memory deposit, SimpleInterestVault vault) internal returns (uint256 shares) {
        // vaults loop every TENOR. e.g. for a 30 day vault, day 30 = 0, day 31 = 1, day 32 = 2
        uint256 numTimePeriodsElapsedAtDepositModTenor =
            deposit.numTimePeriodsElapsedAtDeposit % Tenors.toValue(vault.TENOR());

        uint256 expectedInterestInWei = getExpectedInterestInWei(deposit, vault);

        uint256 expectedSharesInWei = (deposit.amountInWei - expectedInterestInWei);

        assertEq(
            expectedSharesInWei,
            vault.convertToSharesAtNumTimePeriodsElapsed(deposit.amountInWei, numTimePeriodsElapsedAtDepositModTenor),
            string.concat("wrong convertToSharesAtFrequency ", deposit.name)
        );

        vault.setCurrentTimePeriodsElapsed(numTimePeriodsElapsedAtDepositModTenor);

        assertEq(
            expectedSharesInWei,
            vault.previewDeposit(deposit.amountInWei),
            string.concat("wrong previewDeposit ", deposit.name)
        );

        assertEq(
            expectedSharesInWei,
            vault.convertToShares(deposit.amountInWei),
            string.concat("wrong convertToShares ", deposit.name)
        );

        vm.startPrank(deposit.wallet);
        IERC20 vaultAsset = (IERC20)(vault.asset());
        vaultAsset.approve(address(vault), deposit.amountInWei);
        uint256 actualShares = vault.deposit(deposit.amountInWei, deposit.wallet);
        vm.stopPrank();

        assertEq(expectedSharesInWei, actualShares, string.concat("vault balance wrong ", deposit.name));

        return actualShares;
    }

    function previewRedeemAndVerify(Deposit memory deposit, uint256 sharesInWei, SimpleInterestVault vault) public {
        // redeem happens TENOR days after deposit // this is financially
        uint256 numTimePeriodsAtRedeem =
            vault.calcNumTimePeriodsForRedeem(deposit.numTimePeriodsElapsedAtDeposit + Tenors.toValue(vault.TENOR()));

        console2.log("=========== preview redeem for ", deposit.name);

        uint256 previousInterestFrequency = vault.currentTimePeriodsElapsed();

        uint256 expectedAssetsInWei = deposit.amountInWei + getExpectedInterestInWei(deposit, vault);

        // check shares at frequency * 1 (no roll-over)
        assertApproxEqAbs(
            expectedAssetsInWei,
            vault.convertToAssetsAtFrequency(sharesInWei, numTimePeriodsAtRedeem),
            TOLERANCE,
            string.concat("wrong convertToAssetsAtFrequency ", deposit.name)
        );

        vault.setCurrentTimePeriodsElapsed(numTimePeriodsAtRedeem);
        assertApproxEqAbs(
            expectedAssetsInWei,
            vault.previewRedeem(sharesInWei),
            TOLERANCE,
            string.concat("wrong previewRedeem ", deposit.name)
        );
        assertApproxEqAbs(
            expectedAssetsInWei,
            vault.convertToAssets(sharesInWei),
            TOLERANCE,
            string.concat("wrong convertToAssets ", deposit.name)
        );

        vault.setCurrentTimePeriodsElapsed(previousInterestFrequency);
    }

    function redeemAndVerify(Deposit memory deposit, uint256 shares, SimpleInterestVault vault)
        internal
        returns (uint256 assets)
    {
        address wallet = deposit.wallet;
        uint256 expectedAssets = deposit.amountInWei + getExpectedInterestInWei(deposit, vault);

        uint256 numTimePeriodsAtRedeem = vault.calcNumTimePeriodsForRedeem(deposit.numTimePeriodsElapsedAtDeposit);

        vault.setCurrentTimePeriodsElapsed(numTimePeriodsAtRedeem);
        vm.startPrank(wallet);

        uint256 actualAssets = vault.redeem(shares, wallet, wallet);
        assertApproxEqAbs(expectedAssets, actualAssets, TOLERANCE, string.concat("redeem for ", deposit.name));

        vm.stopPrank();

        return actualAssets;
    }

    function transferAndAssert(IERC20 _token, address toAddress, uint256 amount) public {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(owner);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }

    function getExpectedInterestInWei(Deposit memory deposit, SimpleInterestVault vault)
        internal
        view
        returns (uint256)
    {
        uint256 numTimePeriodsForDeposit = vault.calcNumTimePeriodsForDeposit(deposit.numTimePeriodsElapsedAtDeposit);

        return vault.simpleInterest().calcInterest(deposit.amountInWei, numTimePeriodsForDeposit);
    }
}
