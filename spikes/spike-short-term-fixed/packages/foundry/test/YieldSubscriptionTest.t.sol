//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { YieldSubscription } from "../contracts/kk/YieldSubscription.sol";
import { SimpleUSDC } from "../contracts/SimpleUSDC.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { console2 } from "forge-std/console2.sol";

contract YieldSubscriptionTest is Test {
    using EnumerableSet for EnumerableSet.UintSet;

    YieldSubscription subscription;
    SimpleUSDC usdc;
    uint256 virtualStartTime = 1724112000; // 20th August 2024 00.00 AM UTC
    address user = makeAddr("user");

    uint256 public constant DEPOSIT_AMOUNT = 1000e6;

    function setUp() public {
        usdc = new SimpleUSDC(10e12); // 10 Million initial supply
        console2.log("start time at setup", block.timestamp);
        vm.warp(virtualStartTime);
        subscription = new YieldSubscription(address(usdc), virtualStartTime, 30, 2);
        console2.log("start time after setup", subscription.startTime());

        usdc.mint(user, 10 * DEPOSIT_AMOUNT); // 10000 USDC
    }

    function test__Version() public {
        assertEq(subscription.version(), "1.0.0");
    }

    function test__Subscription__YieldWindow() public {
        console2.log("Start time", subscription.startTime());
        vm.warp(virtualStartTime);
        console2.log("Current Window: %s", subscription.getCurrentTimePeriodsElapsed());
        vm.startPrank(user);
        subscription.setCurrentTimePeriodsElapsed(1);
        usdc.approve(address(subscription), DEPOSIT_AMOUNT);
        subscription.deposit(DEPOSIT_AMOUNT, user);

        subscription.setCurrentTimePeriodsElapsed(31);
        console2.log("Yield per window", subscription.yieldPerWindow());
        console2.log("Interest earned", subscription.interestEarnedForWindow(user, 1));
    }

    function test__Subscription__MultiWindowDeposit() public {
        vm.startPrank(user);
        subscription.setCurrentTimePeriodsElapsed(1);
        usdc.approve(address(subscription), 2 * DEPOSIT_AMOUNT);
        subscription.deposit(DEPOSIT_AMOUNT, user);

        uint256[] memory windows = subscription.getUserWindows(user);
        assertEq(windows.length, 1);
        assertEq(windows[0], 1);

        subscription.setCurrentTimePeriodsElapsed(31);
        subscription.deposit(DEPOSIT_AMOUNT, user);
        windows = subscription.getUserWindows(user);
        assertEq(windows.length, 2);
        assertEq(windows[1], 31);

        uint256 totalUserDeposit = subscription.totalUserDeposit(user);
        assertEq(totalUserDeposit, 2 * DEPOSIT_AMOUNT);
    }

    function test__Subscription__Withdraw() public {
        vm.startPrank(user);
        subscription.setCurrentTimePeriodsElapsed(1);
        usdc.approve(address(subscription), DEPOSIT_AMOUNT);
        subscription.deposit(DEPOSIT_AMOUNT, user);
        console2.log("Current Window: %s", subscription.getCurrentTimePeriodsElapsed());

        uint256[] memory windows = subscription.getUserWindows(user);
        assertEq(windows.length, 1);
        assertEq(windows[0], 1);

        subscription.setCurrentTimePeriodsElapsed(31);
        console2.log("Yield per window", subscription.yieldPerWindow());
        uint256 interestEarned = subscription.interestEarnedForWindow(user, 1);
        console2.log("Interest earned", interestEarned);
        uint256 totalUserDeposit = subscription.totalUserDeposit(user);
        console2.log("Total user deposit", totalUserDeposit);
        usdc.mint(address(subscription), interestEarned);
        uint256 transferredBalance = subscription.redeemAtPeriod(DEPOSIT_AMOUNT, user, user, windows[0]);
        console2.log('transferred balance', transferredBalance);
    }

    function test__Subscription__Rollover() public {
        uint256 deposit = 50_000e6;
        vm.startPrank(user);
        usdc.mint(user, deposit);
        usdc.approve(address(subscription), deposit);
        subscription.setCurrentTimePeriodsElapsed(1);
        subscription.deposit(deposit, user);

        subscription.setCurrentTimePeriodsElapsed(32);
        uint256 interestEarned = subscription.interestEarnedForWindow(user, 1);
        console2.log("Interest earned", interestEarned);
    }
}
