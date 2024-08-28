//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { YieldSubscription } from "../../src/subscription/YieldSubscription.sol";
import { SimpleUSDC } from "../test/token/SimpleUSDC.t.sol";
import { YieldToken } from "../../src/subscription/YieldToken.sol";
import { console2 } from "forge-std/console2.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract YieldSubscriptionTest is Test {
    using EnumerableSet for EnumerableSet.UintSet;

    YieldSubscription subscription;
    SimpleUSDC usdc;
    YieldToken yToken;
    uint256 virtualStartTime = 1724112000; // 20th August 2024 00.00 AM UTC
    address user = makeAddr("user");

    uint256 public constant DEPOSIT_AMOUNT = 1000e6;

    function setUp() public {
        usdc = new SimpleUSDC(10e12); // 10 Million initial supply
        yToken = new YieldToken("Yield Token", "YLD");
        console2.log("start time at setup", block.timestamp);
        vm.warp(virtualStartTime);
        subscription = new YieldSubscription(address(usdc), virtualStartTime);
        console2.log("start time after setup", subscription.startTime());

        usdc.mint(user, 10 * DEPOSIT_AMOUNT); // 10000 USDC
    }

    function test__Version() public view {
        assertEq(subscription.version(), "1.0.0");
    }

    function test__Subscription__YieldWindow() public {
        console2.log("Start time", subscription.startTime());
        vm.warp(virtualStartTime);
        console2.log("Current Window: %s", subscription.getCurrentWindow());
        vm.startPrank(user);
        usdc.approve(address(subscription), DEPOSIT_AMOUNT);
        subscription.deposit(DEPOSIT_AMOUNT, user);

        vm.warp(virtualStartTime + 30 days);
        console2.log("Yield per window", subscription.yieldPerWindow());
        console2.log("Interest earned", subscription.interestEarnedForWindow(user, 1));
    }

    function test__Subscription__MultiWindowDeposit() public {
        vm.startPrank(user);
        usdc.approve(address(subscription), 2 * DEPOSIT_AMOUNT);
        subscription.deposit(DEPOSIT_AMOUNT, user);
        uint256[] memory windows = subscription.getUserWindows(user);
        assertEq(windows.length, 1);
        assertEq(windows[0], 1);
        vm.warp(virtualStartTime + 30 days);
        subscription.deposit(DEPOSIT_AMOUNT, user);
        windows = subscription.getUserWindows(user);
        assertEq(windows.length, 2);
        assertEq(windows[1], 31);

        uint256 totalUserDeposit = subscription.totalUserDeposit(user);
        assertEq(totalUserDeposit, 2 * DEPOSIT_AMOUNT);
    }

    function test__Subscription__Withdraw() public {
        vm.startPrank(user);
        usdc.approve(address(subscription), DEPOSIT_AMOUNT);
        subscription.deposit(DEPOSIT_AMOUNT, user);
        console2.log("Current Window: %s", subscription.getCurrentWindow());
        uint256[] memory windows = subscription.getUserWindows(user);
        assertEq(windows.length, 1);
        assertEq(windows[0], 1);
        vm.warp(virtualStartTime + 30 days);
        console2.log("Yield per window", subscription.yieldPerWindow());
        console2.log("Interest earned", subscription.interestEarnedForWindow(user, 1));
        console2.log("Eligible amount", subscription.calculateEligibleAmount(user));
        subscription.withdraw(1000, user);
    }
}
