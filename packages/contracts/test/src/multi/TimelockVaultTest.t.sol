// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockVault } from "./TimelockVault.s.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TimelockVaultTest is Test {
    TimelockVault private vault;
    ERC20 private underlyingAsset;
    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    uint256 private lockDuration = 30 days;
    uint256 private initialSupply = 1000000;

    function setUp() public {
        // Setup the underlying asset token and mint some to the owner
        vm.startPrank(owner);
        underlyingAsset = new SimpleToken(initialSupply);
        vm.stopPrank();

        vault = new TimelockVault(underlyingAsset, "VaultToken", "VT", lockDuration);
    }

    function test__TimelockVault__DepositAndLock() public {
        uint256 depositAmount = 1000;

        // Transfer underlying assets to Alice
        vm.startPrank(owner);
        underlyingAsset.transfer(alice, depositAmount);
        vm.stopPrank();

        vm.startPrank(alice);
        underlyingAsset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        (uint256 lockedAmount, uint256 releaseTime) = vault.getLockInfo(alice);

        assertEq(lockedAmount, depositAmount, "Incorrect locked amount");
        assertEq(releaseTime, block.timestamp + lockDuration, "Incorrect release time");

        // Ensure redemption fails before the lock period is over
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(TimelockVault.SharesLocked.selector, releaseTime));
        vault.redeem(depositAmount, alice, alice);
        vm.stopPrank();
    }

    function test__TimelockVault__RedeemAfterUnlock() public {
        uint256 depositAmount = 1000;

        // Transfer underlying assets to Alice
        vm.startPrank(owner);
        underlyingAsset.transfer(alice, depositAmount);
        vm.stopPrank();

        vm.startPrank(alice);
        underlyingAsset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, alice);
        vm.stopPrank();

        // Fast forward time to after the lock period
        vm.warp(block.timestamp + lockDuration + 1);

        // Redemption should succeed after the lock period
        vm.startPrank(alice);
        uint256 assets = vault.redeem(depositAmount, alice, alice);
        vm.stopPrank();

        assertEq(assets, depositAmount, "Redemption after unlock failed");
        assertEq(underlyingAsset.balanceOf(alice), depositAmount, "Alice should have the redeemed assets");
        assertEq(vault.balanceOf(alice), 0, "Alice should have no vault shares left");
    }

    function test__TimelockVault__TransferNotSupported() public {
        vm.startPrank(alice);
        vm.expectRevert(TimelockVault.TransferNotSupported.selector);
        vault.transfer(owner, 1);
        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert(TimelockVault.TransferNotSupported.selector);
        vault.transferFrom(alice, owner, 1);
        vm.stopPrank();
    }
}
