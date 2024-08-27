// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console2 as console } from "forge-std/console2.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { OwnableToken } from "./OwnableToken.t.sol";
import { BatchTimeLockVault } from "../contracts/BatchTimeLockVault.sol";

contract BatchTimeLockVaultTest is Test {
    uint256 private constant LOCK_DURATION = 3 days;
    uint256 private constant ASSET_INITIAL_SUPPLY = 1_000_000;
    uint256 private constant VAULT_TOTAL_SUPPLY = 1_000_000_000;

    address private immutable OWNER = makeAddr("OWNER");
    address private immutable ALICE = makeAddr("ALICE");
    address private immutable BOB = makeAddr("BOB");

    ERC20 private underlyingAsset;
    BatchTimeLockVault private vault;

    uint256 depositAmount = 1_000 * assetScale();
    uint256 maxAmount = depositAmount * 10;
    uint256[] allShares = new uint256[](3);

    function setUp() public {
        vm.startPrank(OWNER);
        underlyingAsset = new OwnableToken("Fake USDC", "fUSDC", 6, ASSET_INITIAL_SUPPLY * 10 ** 6);
        vm.stopPrank();

        vault = new BatchTimeLockVault(underlyingAsset, LOCK_DURATION, VAULT_TOTAL_SUPPLY * 10 ** 6);
    }

    function assetScale() private view returns (uint256) {
        return 10 ** underlyingAsset.decimals();
    }

    function setupScenario() private {
        vm.startPrank(OWNER);
        underlyingAsset.transfer(address(vault), maxAmount);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        allShares[0] = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        allShares[1] = vault.deposit(depositAmount + (5 * assetScale()), ALICE);
        vm.warp(vm.getBlockTimestamp() + 1 days);
        allShares[2] = vault.deposit(depositAmount + (10 * assetScale()), ALICE);
        vm.warp(vm.getBlockTimestamp() + 1 days);
        vm.stopPrank();
    }

    function test_BatchTimeLockVault_EnsureRedeemWorks() public {
        setupScenario();

        assertEq(3, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares,) = vault.getLockFor(ALICE, i);
            assertEq(allShares[i], lockedShares, "Invalid share amount");
        }

        // Ensure that redeem works.
        vm.startPrank(ALICE);
        vault.redeem(allShares[0], ALICE, ALICE);
        vm.stopPrank();

        assertEq(2, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares,) = vault.getLockFor(ALICE, i);
            assertEq(allShares[i + 1], lockedShares, "Invalid share amount");
        }
    }

    function __CalculateTimeWindowsFromBlockTimestamp() public pure {
        // uint256 ts = vm.getBlockTimestamp(); // now
        uint256 ts = 2510 weeks + 17 hours + 54 minutes + 22 seconds; // A random time point.
        uint256 dayRemainder = ts % 1 days; // the number of seconds elapsed today since midnight
        uint32 manualDayRemainder = 17 hours + 54 minutes + 22 seconds;
        uint256 midnightPast = ts - dayRemainder;
        uint256 midnightNext = midnightPast + 1 days;

        console.log("Now=", ts);
        console.log("Normalised?=", ts * 1 days);
        console.log("1 Day=", 1 days, "Day Remainder=", dayRemainder);
        console.log("Manual Day Remainder=", manualDayRemainder);
        console.log("Midnight Past=", midnightPast);
        console.log("Midnight Next=", midnightNext);
    }
}
