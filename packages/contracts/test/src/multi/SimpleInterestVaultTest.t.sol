// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

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

    uint256 public constant TOLERANCE = 500; // with 18 decimals, means allowed difference of 5E+16

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

    //     constructor(IERC20 asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
    function test__SimpleInterestVault__Monthly_24Months() public {
        uint256 apy = 12; // APY in percentage, e.g. 12%
        Frequencies.Frequency frequencyMonthly = Frequencies.Frequency.MONTHLY;
        uint256 tenorThreeMonths = 3;

        uint256 principal = 100 ether;

        SimpleInterestVault vault =
            new SimpleInterestVault(asset, apy, Frequencies.toValue(frequencyMonthly), tenorThreeMonths);

        // check all periods for 24 months
        for (uint256 i = 0; i <= 24; i++) {
            uint256 numTimePeriodsAtDeposit = i;
            uint256 redeemTimePeriod = numTimePeriodsAtDeposit + tenorThreeMonths; // redeem Time is always tenor time later
            uint256 expectedYield = vault.calcInterest(principal, tenorThreeMonths); // expected yield is always a full tenor

            // check shares
            uint256 expectedShares =
                principal - vault.calcInterest(principal, numTimePeriodsAtDeposit % tenorThreeMonths);
            uint256 actualShares = vault.calcSharesAtPeriod(principal, numTimePeriodsAtDeposit);
            assertEq(expectedShares, actualShares, string.concat("shares mismatch at month ", vm.toString(i)));

            // check principal
            uint256 actualPrincipal = vault.calcPrincipalAtPeriod(actualShares, redeemTimePeriod);
            assertEq(principal, actualPrincipal, string.concat("principal mismatch at month ", vm.toString(i)));

            // check assets
            uint256 actualAssets = vault.calcAssetsAtPeriod(actualShares, redeemTimePeriod);
            assertEq(principal + expectedYield, actualAssets, string.concat("asset mismatch at month ", vm.toString(i)));
        }
    }

    function test__SimpleInterestVault__Monthly_1_2_12() public {
        uint256 apy = 12; // APY in percentage
        Frequencies.Frequency frequencyMonthly = Frequencies.Frequency.MONTHLY;
        uint256 tenorThreeMonths = 3;

        SimpleInterestVault vault =
            new SimpleInterestVault(asset, apy, Frequencies.toValue(frequencyMonthly), tenorThreeMonths);

        Deposit memory depositAlice = Deposit("alice 1 month", alice, 200 ether, 1);
        Deposit memory depositBob = Deposit("bob 2 months", bob, 100 ether, 2);
        Deposit memory depositCharlie = Deposit("charlie 12 months", charlie, 300 ether, 12);

        verifySimpleInterestVault(vault, depositAlice, depositBob, depositCharlie);
    }

    function test__SimpleInterestVault__Daily_0_1_2() public {
        uint256 apy = 10; // APY in percentage
        Frequencies.Frequency frequencyDaily365 = Frequencies.Frequency.DAYS_365;
        uint256 tenorDays90 = 90;

        SimpleInterestVault vault =
            new SimpleInterestVault(asset, apy, Frequencies.toValue(frequencyDaily365), tenorDays90);

        Deposit memory depositAlice = Deposit("alice 0 days", alice, 200 ether, 0);
        Deposit memory depositBob = Deposit("bob 2 day", bob, 100 ether, 1);
        Deposit memory depositCharlie = Deposit("charlie 3 days", charlie, 300 ether, 2);

        verifySimpleInterestVault(vault, depositAlice, depositBob, depositCharlie);
    }

    // represents the second cycle - days 30, 31, 32 (equiv to 1,2,3)
    function test__SimpleInterestVault__Daily_30_31_32() public {
        uint256 apy = 10; // APY in percentage
        Frequencies.Frequency frequencyDaily365 = Frequencies.Frequency.DAYS_365;
        uint256 tenorDays90 = 90;

        SimpleInterestVault vault =
            new SimpleInterestVault(asset, apy, Frequencies.toValue(frequencyDaily365), tenorDays90);

        Deposit memory depositAlice = Deposit("alice 30 days", alice, 200 ether, 30);
        Deposit memory depositBob = Deposit("bob 31 days", bob, 100 ether, 31); // 365 / 5 = 73
        Deposit memory depositCharlie = Deposit("charlie 32 days", charlie, 300 ether, 32);

        verifySimpleInterestVault(vault, depositAlice, depositBob, depositCharlie);
    }

    // represents the second cycle - days 30, 31, 32 (equiv to 1,2,3)
    function test__SimpleInterestVault__Daily_10_20_29() public {
        uint256 apy = 10; // APY in percentage
        Frequencies.Frequency frequencyDaily365 = Frequencies.Frequency.DAYS_365;
        uint256 tenorDays90 = 90;

        SimpleInterestVault vault =
            new SimpleInterestVault(asset, apy, Frequencies.toValue(frequencyDaily365), tenorDays90);

        Deposit memory depositAlice = Deposit("alice 10 days", alice, 200 ether, 10);
        Deposit memory depositBob = Deposit("bob 20 days", bob, 100 ether, 20); // 365 / 5 = 73
        Deposit memory depositCharlie = Deposit("charlie 29 days", charlie, 300 ether, 29);

        verifySimpleInterestVault(vault, depositAlice, depositBob, depositCharlie);
    }

    struct Deposit {
        string name;
        address wallet;
        uint256 amountInWei;
        // vault state at time of deposit
        uint256 numTimePeriodsElapsedAtDeposit;
    }

    function verifySimpleInterestVault(
        SimpleInterestVault vault,
        Deposit memory depositAlice,
        Deposit memory depositBob,
        Deposit memory depositCharlie
    ) internal {
        console2.log("================ start deposit ==============");

        uint256 sharesInWeiAlice = depositAndVerify(depositAlice, vault);
        uint256 sharesInWeiBob = depositAndVerify(depositBob, vault);
        uint256 sharesInWeiCharlie = depositAndVerify(depositCharlie, vault);

        console2.log("!! sharesInWeiAlice", sharesInWeiAlice);
        console2.log("!! sharesInWeiBob", sharesInWeiBob);
        console2.log("!! sharesInWeiCharlie", sharesInWeiCharlie);

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
        uint256 numTimePeriodsElapsedAtDepositModTenor = vault.calculateCycle(deposit.numTimePeriodsElapsedAtDeposit);

        uint256 expectedInterestInWei = vault.calcInterest(deposit.amountInWei, numTimePeriodsElapsedAtDepositModTenor);

        uint256 expectedSharesInWei = (deposit.amountInWei - expectedInterestInWei);

        assertEq(
            expectedSharesInWei,
            vault.calcSharesAtPeriod(deposit.amountInWei, numTimePeriodsElapsedAtDepositModTenor),
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
        uint256 numTimePeriodsAtRedeem = deposit.numTimePeriodsElapsedAtDeposit + vault.TENOR(); // redeem happens TENOR days after deposit

        uint256 previousInterestFrequency = vault.currentTimePeriodsElapsed();

        assertApproxEqAbs(
            deposit.amountInWei,
            vault.calcPrincipalAtPeriod(sharesInWei, numTimePeriodsAtRedeem),
            TOLERANCE,
            string.concat("wrong convertToPrincipalAtNumTimePeriodsElapsed ", deposit.name)
        );

        uint256 expectedAssetsInWei = deposit.amountInWei + vault.calcInterest(deposit.amountInWei, vault.TENOR()); // full tenor of interest

        assertApproxEqAbs(
            expectedAssetsInWei,
            vault.calcAssetsAtPeriod(sharesInWei, numTimePeriodsAtRedeem),
            TOLERANCE,
            string.concat("wrong convertToAssetsAtNumTimePeriodsElapsed ", deposit.name)
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
        uint256 expectedAssetsInWei = deposit.amountInWei + vault.calcInterest(deposit.amountInWei, vault.TENOR()); // full tenor of interest
        uint256 numTimePeriodsAtRedeem = deposit.numTimePeriodsElapsedAtDeposit + vault.TENOR(); // redeem happens TENOR days after deposit

        vault.setCurrentTimePeriodsElapsed(numTimePeriodsAtRedeem);
        vm.startPrank(wallet);

        uint256 actualAssets = vault.redeem(shares, wallet, wallet);
        assertApproxEqAbs(expectedAssetsInWei, actualAssets, TOLERANCE, string.concat("redeem for ", deposit.name));

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
}
