// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console2 as console } from "forge-std/console2.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { OwnableToken } from "./OwnableToken.t.sol";
import { TimeLockVault } from "../contracts/TimeLockVault.sol";

contract TimeLockVaultTest is Test {
    address private immutable OWNER = makeAddr("OWNER");
    address private immutable ALICE = makeAddr("ALICE");
    uint256 private constant LOCK_DURATION = 3 days;
    uint256 private constant INITIAL_SUPPLU = 1_000_000;
    ERC20 private underlyingAsset;
    TimeLockVault private vault;

    function setUp() public {
        vm.startPrank(OWNER);
        underlyingAsset = new OwnableToken("Asset", "AST", 18, 10_000);
        vm.stopPrank();

        vault = new TimeLockVault(underlyingAsset, LOCK_DURATION);
    }

    function test_TimeLockVault_SharesAreLockedOnDeposit() public {
        uint256 depositAmount = 1_000;
        uint256 maxAmount = depositAmount * 10;

        // Transfer underlying assets to Alice
        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        vm.stopPrank();

        assertEq(1, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares1, uint256 lockedUntil1) = vault.getLockFor(ALICE, i);
            assertEq(shares, lockedShares1, "Invalid share amount");
            assertLt(vm.getBlockTimestamp(), lockedUntil1, "Block Timestamp is greater that Locked Until");
        }
    }

    function test_TimeLockVault_RedemptionFails_WhenSharesAreLocked() public {
        uint256 depositAmount = 1_000;
        uint256 maxAmount = depositAmount * 10;

        // Transfer underlying assets to Alice
        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        vm.stopPrank();

        // Ensure redemption fails before the lock period is over
        vm.startPrank(ALICE);
        vm.expectRevert(TimeLockVault.SharesLocked.selector);
        vault.redeem(shares, ALICE, ALICE);
        vm.stopPrank();
    }

    function test_TimeLockVault_AllShareAllocationsLockedOnDeposit() public {
        uint256 depositAmount = 1_000;
        uint256 maxAmount = depositAmount * 10;

        // Transfer underlying assets to Alice
        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares1 = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares2 = vault.deposit(depositAmount + 5, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares3 = vault.deposit(depositAmount + 10, ALICE);
        vm.stopPrank();

        uint256[] memory allShares = new uint256[](3);
        allShares[0] = shares1;
        allShares[1] = shares2;
        allShares[2] = shares3;

        assertEq(3, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares1, uint256 lockedUntil1) = vault.getLockFor(ALICE, i);
            assertEq(allShares[i], lockedShares1, "Invalid share amount");
            assertLt(vm.getBlockTimestamp(), lockedUntil1, "Block Timestamp is greater that Locked Until");
        }

        // Ensure redemption fails before the lock period is over
        vm.startPrank(ALICE);
        vm.expectRevert(TimeLockVault.SharesLocked.selector);
        vault.redeem(shares1, ALICE, ALICE);
        vm.expectRevert(TimeLockVault.SharesLocked.selector);
        vault.redeem(shares2, ALICE, ALICE);
        vm.expectRevert(TimeLockVault.SharesLocked.selector);
        vault.redeem(shares3, ALICE, ALICE);
        vm.stopPrank();
    }

    function test_TimeLockVault_RedemptionPossibleOnUnlock() public {
        uint256 depositAmount = 1_000;
        uint256 maxAmount = depositAmount * 10;

        // Transfer underlying assets to Alice
        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        vm.stopPrank();

        assertEq(1, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        (uint256 lockedShares1, uint256 lockedUntil1) = vault.getLockFor(ALICE, 0);
        assertEq(shares, lockedShares1, "Invalid share amount");
        assertLt(vm.getBlockTimestamp(), lockedUntil1, "Block Timestamp is greater than Locked Until");

        // Ensure redemption succeeds after the lock period is over
        vm.warp(lockedUntil1 + 1);
        assertGt(vm.getBlockTimestamp(), lockedUntil1, "Block Timestamp is less than Locked Until");
        assertGt(block.timestamp, lockedUntil1, "Block Timestamp is less than Locked Until");
        vm.startPrank(ALICE);
        vault.redeem(shares, ALICE, ALICE);
        vm.stopPrank();

        assertEq(0, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
    }

    function test_TimeLockVault_ForMultipleDeposits_RedemptionPossibleOnUnlock() public {
        uint256 depositAmount = 1_000;
        uint256 maxAmount = depositAmount * 10;

        // Transfer underlying assets to Alice
        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares1 = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares2 = vault.deposit(depositAmount + 5, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares3 = vault.deposit(depositAmount + 10, ALICE);
        vm.stopPrank();

        uint256[] memory allShares = new uint256[](3);
        allShares[0] = shares1;
        allShares[1] = shares2;
        allShares[2] = shares3;

        assertEq(3, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares1, uint256 lockedUntil1) = vault.getLockFor(ALICE, i);
            assertEq(allShares[i], lockedShares1, "Invalid share amount");
            assertLt(vm.getBlockTimestamp(), lockedUntil1, "Block Timestamp is greater that Locked Until");
        }

        // Ensure redemption succeeds after the lock period is over
        (uint256 lockedShares, uint256 lockedUntil) = vault.getLockFor(ALICE, 0);
        vm.warp(lockedUntil + 1);
        vm.startPrank(ALICE);
        vault.redeem(lockedShares, ALICE, ALICE);
        vm.stopPrank();

        uint256[] memory allShares1 = new uint256[](2);
        allShares1[0] = shares2;
        allShares1[1] = shares3;

        assertEq(2, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares2, uint256 lockedUntil2) = vault.getLockFor(ALICE, i);
            assertEq(allShares1[i], lockedShares2, "Invalid share amount");
            assertLt(vm.getBlockTimestamp(), lockedUntil2, "Block Timestamp is greater that Locked Until");
        }
    }

    function test_TimeLockVault_ForMultipleDeposits_RedemptionPossibleOnUnlock_MatchedShares() public {
        uint256 depositAmount = 1_000;
        uint256 maxAmount = depositAmount * 10;

        // Transfer underlying assets to Alice
        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares1 = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares2 = vault.deposit(depositAmount + 5, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares3 = vault.deposit(depositAmount + 10, ALICE);
        vm.stopPrank();

        uint256[] memory allShares = new uint256[](3);
        allShares[0] = shares1;
        allShares[1] = shares2;
        allShares[2] = shares3;

        assertEq(3, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares1, uint256 lockedUntil1) = vault.getLockFor(ALICE, i);
            assertEq(allShares[i], lockedShares1, "Invalid share amount");
            assertLt(vm.getBlockTimestamp(), lockedUntil1, "Block Timestamp is greater that Locked Until");
        }

        // Ensure redemption succeeds after the lock period is over
        (uint256 lockedShares, uint256 lockedUntil) = vault.getLockFor(ALICE, 0);
        vm.warp(lockedUntil + 1);
        vm.startPrank(ALICE);
        vault.redeem(lockedShares, ALICE, ALICE);
        vm.stopPrank();

        uint256[] memory allShares1 = new uint256[](2);
        allShares1[0] = shares2;
        allShares1[1] = shares3;

        assertEq(2, vault.getLockCountFor(ALICE), "Incorrect number of locked deposits");
        for (uint256 i = 0; i < vault.getLockCountFor(ALICE); i++) {
            (uint256 lockedShares2, uint256 lockedUntil2) = vault.getLockFor(ALICE, i);
            assertEq(allShares1[i], lockedShares2, "Invalid share amount");
            assertLt(vm.getBlockTimestamp(), lockedUntil2, "Block Timestamp is greater that Locked Until");
        }
    }
}
