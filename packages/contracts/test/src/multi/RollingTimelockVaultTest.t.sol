// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { RollingTimelockVault, LockInfo } from "./RollingTimelockVault.s.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Test } from "forge-std/Test.sol";

contract RollingTimelockVaultTest is Test {
    IERC20 private asset;
    RollingTimelockVault private timelockVault;
    address private immutable owner = makeAddr("owner");

    function setUp() public {
        uint256 tokenSupply = 100000;

        vm.startPrank(owner);
        asset = new SimpleToken(tokenSupply);
        timelockVault = new RollingTimelockVault(asset, "Vault Shares", "vTST");

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");

        vm.stopPrank();
    }

    function test__RollingTimelockVault__DepositAndLockShares() public {
        uint256 depositAmount = 200;

        vm.startPrank(owner);
        asset.approve(address(timelockVault), depositAmount);
        uint256 shares = timelockVault.deposit(depositAmount, owner);

        assertEq(timelockVault.balanceOf(owner), shares);

        // Check that the shares are locked
        LockInfo[] memory locks = timelockVault.getLocks(owner);
        assertEq(locks.length, 1);
        assertEq(locks[0].shares, shares);

        vm.stopPrank();
    }

    function test__RollingTimelockVault__LockInfoMultipleDeposits() public {
        uint256 depositAmount1 = 200;
        uint256 depositAmount2 = 300;

        vm.startPrank(owner);

        // First deposit
        asset.approve(address(timelockVault), depositAmount1);
        uint256 shares1 = timelockVault.deposit(depositAmount1, owner);

        // Check that the first deposit is locked
        LockInfo[] memory locks1 = timelockVault.getLocks(owner);
        assertEq(locks1.length, 1);
        assertEq(locks1[0].shares, shares1);

        // Fast forward time by 15 days
        vm.warp(block.timestamp + 15 days);

        // Second deposit with a different release time (because of the time warp)
        asset.approve(address(timelockVault), depositAmount2);
        uint256 shares2 = timelockVault.deposit(depositAmount2, owner);

        // Check that there are two locks because the release times are different
        LockInfo[] memory locks2 = timelockVault.getLocks(owner);
        assertEq(locks2.length, 2);
        assertEq(locks2[0].shares, shares1);
        assertEq(locks2[1].shares, shares2);

        // Now deposit again without time warp, so the lock should be updated
        asset.approve(address(timelockVault), depositAmount1);
        uint256 shares3 = timelockVault.deposit(depositAmount1, owner);

        // Check that the second lock is updated because the release time is the same
        locks2 = timelockVault.getLocks(owner);
        assertEq(locks2.length, 2);
        assertEq(locks2[1].shares, shares2 + shares3);

        vm.stopPrank();
    }

    function test__RollingTimelockVault__RedeemFailsIfSharesAreLocked() public {
        uint256 depositAmount = 200;

        // owner deposits assets
        vm.startPrank(owner);
        asset.approve(address(timelockVault), depositAmount);
        uint256 shares = timelockVault.deposit(depositAmount, owner);

        // Attempt to redeem shares before they are unlocked
        vm.expectRevert("Not enough unlocked shares");
        timelockVault.redeem(shares, owner, owner);

        vm.stopPrank();
    }

    function test__RollingTimelockVault__PartialRedeemUpdatesCorrectLock() public {
        uint256 depositAmount = 200;

        // owner deposits assets
        vm.startPrank(owner);
        asset.approve(address(timelockVault), depositAmount);
        uint256 shares = timelockVault.deposit(depositAmount, owner);

        // Fast forward time by 30 days to unlock the shares
        vm.warp(block.timestamp + 30 days);

        // Redeem a portion of the unlocked shares
        uint256 redeemAmount = 50;
        uint256 redeemedAssets = timelockVault.redeem(redeemAmount, owner, owner);
        assertEq(redeemedAssets, redeemAmount);

        // Check that the remaining shares are still locked
        LockInfo[] memory locks = timelockVault.getLocks(owner);
        assertEq(locks.length, 1);
        assertEq(locks[0].shares, shares - redeemAmount);

        vm.stopPrank();
    }

    function test__RollingTimelockVault__FullRedeemClearsLock() public {
        uint256 depositAmount = 200;

        // owner deposits assets
        vm.startPrank(owner);
        asset.approve(address(timelockVault), depositAmount);
        uint256 shares = timelockVault.deposit(depositAmount, owner);

        // Fast forward time by 30 days to unlock the shares
        vm.warp(block.timestamp + 30 days);

        // Redeem all the unlocked shares
        uint256 redeemedAssets = timelockVault.redeem(shares, owner, owner);
        assertEq(redeemedAssets, shares);

        // Check that the lock is cleared
        LockInfo[] memory locks = timelockVault.getLocks(owner);
        assertEq(locks[0].shares, 0);

        vm.stopPrank();
    }

    function test__RollingTimelockVault__RedeemWithMultipleLocks() public {
        uint256 depositAmount1 = 200;
        uint256 depositAmount2 = 300;

        // owner deposits first amount
        vm.startPrank(owner);
        asset.approve(address(timelockVault), depositAmount1);
        uint256 shares1 = timelockVault.deposit(depositAmount1, owner);

        // Fast forward time by 15 days
        vm.warp(block.timestamp + 15 days);

        // owner deposits second amount
        asset.approve(address(timelockVault), depositAmount2);
        uint256 shares2 = timelockVault.deposit(depositAmount2, owner);

        // Fast forward time by 15 more days to unlock the first deposit only
        vm.warp(block.timestamp + 15 days);

        // Redeem shares partially, should deduct from the first lock
        uint256 redeemAmount = 150;
        uint256 redeemedAssets = timelockVault.redeem(redeemAmount, owner, owner);
        assertEq(redeemedAssets, redeemAmount);

        // Check that the first lock is reduced and the second lock is untouched
        LockInfo[] memory locks = timelockVault.getLocks(owner);
        assertEq(locks.length, 2);
        assertEq(locks[0].shares, shares1 - redeemAmount);
        assertEq(locks[1].shares, shares2);

        vm.stopPrank();
    }

    function test__RollingTimelockVault__RedeemAfter30Days() public {
        uint256 depositAmount = 200;

        // owner deposits assets
        vm.startPrank(owner);
        asset.approve(address(timelockVault), depositAmount);
        uint256 shares = timelockVault.deposit(depositAmount, owner);

        // Fast forward time by 30 days
        vm.warp(block.timestamp + 30 days);

        // Now redeem should succeed
        uint256 redeemedAssets = timelockVault.redeem(shares, owner, owner);
        assertEq(redeemedAssets, depositAmount);
        assertEq(timelockVault.balanceOf(owner), 0);

        vm.stopPrank();
    }

    function transferAndAssert(IERC20 _token, address toAddress, uint256 amount) public {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(owner);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
