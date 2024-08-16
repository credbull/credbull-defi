// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { Frequencies } from "./Frequencies.s.sol";

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";
import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";

contract SimpleInterestVaultTest is Test {
    using Math for uint256;

    IERC20 private token;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");

    function setUp() public {
        uint256 tokenSupply = 100000;

        vm.startPrank(owner);
        token = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 1000;

        assertEq(token.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(token, alice, userTokenAmount);
        transferAndAssert(token, bob, userTokenAmount);
        transferAndAssert(token, charlie, userTokenAmount);
    }

    function test__SimpleInterestVault_Annual() public {
        uint256 apy = 12; // APY in percentage, e.g. 12%

        Deposit memory depositAlice = Deposit("alice 0 years", alice, 200, 0);
        Deposit memory depositBob = Deposit("bob 1 year", bob, 100, 1);
        Deposit memory depositCharlie = Deposit("bob 2 years", charlie, 500, 2);

        simpleInterestVaultTesDaily(apy, Frequencies.YEARS_ONE, depositAlice, depositBob, depositCharlie);
    }

    function test__SimpleInterestVault_Daily() public {
        uint256 apy = 6; // APY in percentage, e.g. 12%

        Deposit memory depositAlice = Deposit("alice 0 days", alice, 400, 0);
        Deposit memory depositBob = Deposit("bob 180 days", bob, 300, 180);
        Deposit memory depositCharlie = Deposit("charlie 360 days", charlie, 600, 360);

        simpleInterestVaultTesDaily(apy, Frequencies.DAYS_360, depositAlice, depositBob, depositCharlie);
    }

    struct Deposit {
        string name;
        address wallet;
        uint256 amount;
        uint256 frequency;
    }

    function simpleInterestVaultTesDaily(
        uint256 apy,
        uint256 frequency,
        Deposit memory depositAlice,
        Deposit memory depositBob,
        Deposit memory depositCharlie
    ) internal {
        // set up vault
        SimpleInterest simpleInterest = new SimpleInterest(apy, frequency);
        SimpleInterestVault vault = new SimpleInterestVault(token, simpleInterest);

        uint256 sharesAlice = depositAndVerify(depositAlice, vault);
        uint256 sharesBob = depositAndVerify(depositBob, vault);
        uint256 sharesCharlie = depositAndVerify(depositCharlie, vault);

        // ============== redeem ==============
        console2.log("================ start redeem ==============");

        // verify the previewRedeem and convertToAsset (these don't actually redeem)
        previewRedeemAndVerify(depositAlice, sharesAlice, vault);
        previewRedeemAndVerify(depositBob, sharesBob, vault);
        previewRedeemAndVerify(depositCharlie, sharesCharlie, vault);

        // add enough interest to cover all redeems
        vm.startPrank(owner);
        token.transfer(address(vault), (depositAlice.amount + depositBob.amount + depositCharlie.amount)); // enough for 100% interest
        vm.stopPrank();

        // now actually redeem - exchange shares back for assets
        redeemAndVerify(depositAlice, sharesAlice, vault);
        redeemAndVerify(depositBob, sharesBob, vault);
        redeemAndVerify(depositCharlie, sharesCharlie, vault);
    }

    function depositAndVerify(Deposit memory deposit, SimpleInterestVault vault) internal returns (uint256 shares) {
        uint256 expectedInterest = getExpectedInterest(deposit, vault.simpleInterest());
        uint256 expectedShares = (deposit.amount - expectedInterest);

        // assertVaultSharesCalculation(vault, deposit.amount, expectedInterest, deposit.frequency, string.concat("frequency ", deposit.name));
        assertEq(
            expectedShares,
            vault.convertToSharesAtFrequency(deposit.amount, deposit.frequency),
            string.concat("wrong convertToSharesAtFrequency ", deposit.name)
        );

        vault.setCurrentInterestFrequency(deposit.frequency);

        assertEq(
            expectedShares, vault.previewDeposit(deposit.amount), string.concat("wrong previewDeposit ", deposit.name)
        );
        assertEq(
            expectedShares, vault.convertToShares(deposit.amount), string.concat("wrong convertToShares ", deposit.name)
        );

        vm.startPrank(deposit.wallet);
        IERC20 vaultAsset = (IERC20)(vault.asset());
        vaultAsset.approve(address(vault), deposit.amount);
        uint256 actualShares = vault.deposit(deposit.amount, deposit.wallet);
        vm.stopPrank();

        assertEq(expectedShares, actualShares, string.concat("vault balance wrong ", deposit.name));

        return actualShares;
    }

    function previewRedeemAndVerify(Deposit memory deposit, uint256 shares, SimpleInterestVault vault) public {
        console2.log("=========== preview redeem for ", deposit.name);

        uint256 previousInterestFrequency = vault.currentInterestFrequency();

        uint256 expectedAssets = deposit.amount + getExpectedInterest(deposit, vault.simpleInterest());

        assertEq(
            expectedAssets,
            vault.convertToAssetsAtFrequency(shares, deposit.frequency),
            string.concat("wrong convertToAssetsAtFrequency ", deposit.name)
        );

        vault.setCurrentInterestFrequency(deposit.frequency);
        assertEq(expectedAssets, vault.previewRedeem(shares), string.concat("wrong previewRedeem ", deposit.name));
        assertEq(expectedAssets, vault.convertToAssets(shares), string.concat("wrong convertToAssets ", deposit.name));

        vault.setCurrentInterestFrequency(previousInterestFrequency);
    }

    function redeemAndVerify(Deposit memory deposit, uint256 shares, SimpleInterestVault vault)
        internal
        returns (uint256 assets)
    {
        address wallet = deposit.wallet;
        uint256 expectedAssets = deposit.amount + getExpectedInterest(deposit, vault.simpleInterest());

        vault.setCurrentInterestFrequency(deposit.frequency);
        vm.startPrank(wallet);

        uint256 actualAssets = vault.redeem(shares, wallet, wallet);
        assertEq(expectedAssets, actualAssets, string.concat("redeem for ", deposit.name));

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

    function getExpectedInterest(Deposit memory deposit, SimpleInterest simpleInterest)
        internal
        view
        returns (uint256 expectedInterest)
    {
        return simpleInterest.interest(deposit.amount, deposit.frequency);
    }
}
