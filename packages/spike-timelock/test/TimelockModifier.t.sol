// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimelockModifier.sol";
import "../src/test/MockSafe.sol";
import "../src/test/Button.sol";
import "../src/test/ButtonPushModule.sol";
import {Enum, Modifier} from "@gnosis.pm/zodiac/contracts/core/Modifier.sol";

contract TimelockModifierTest is Test {

    uint256 private cooldown = 180;
    uint256 private expiration = 180 * 1000;

    MockSafe private safe;
    Button private button;
    ButtonPushModule private module;
    TimelockModifier private timelock;

    function setUp() public {
        safe = new MockSafe();
        timelock = new TimelockModifier(address(safe), address(safe), address(safe), cooldown, expiration);

        button = new Button();
        button.transferOwnership(address(safe));
        module = new ButtonPushModule(address(timelock), address(button));

        safe.enableModule(address(timelock));
        safe.exec(payable(address(timelock)), 0, abi.encodeWithSelector(Modifier.enableModule.selector, address(module)));

    }

    function testShouldNotExecutePush() public {
        // button shouldn't be pushed as the transaction was only queued
        module.pushButton();
        assertEq(button.pushes(), 0);

        // executing transaction before cooldown
        vm.expectRevert("Transaction is still in cooldown");
        timelock.executeNextTx(address(button), 0, abi.encodeWithSelector(ButtonPushModule.pushButton.selector), Enum.Operation.Call);
    }

    function testShouldExecutePush() public {
        // button shouldn't be pushed as the transaction was only queued
        module.pushButton();
        assertEq(button.pushes(), 0);

        // warping past cooldown
        vm.warp(181);

        // transaction correctly executed
        timelock.executeNextTx(address(button), 0, abi.encodeWithSelector(ButtonPushModule.pushButton.selector), Enum.Operation.Call);
        assertEq(button.pushes(), 1);
    }
}
