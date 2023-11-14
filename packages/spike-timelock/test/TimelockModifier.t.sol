// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimelockModifier.sol";
import "../src/test/MockSafe.sol";
import "../src/test/Button.sol";
import "../src/test/ButtonPushModule.sol";
import { Enum, Modifier } from "@gnosis.pm/zodiac/contracts/core/Modifier.sol";

contract TimelockModifierTest is Test {
    uint64 private cooldown = 180;

    MockSafe private safe;
    Button private button;
    ButtonPushModule private module;
    TimelockModifier private timelock;

    function setUp() public {
        safe = new MockSafe();
        timelock = new TimelockModifier(
            address(safe), address(safe), address(safe), uint64(block.timestamp), uint64(block.timestamp) + cooldown
        );

        button = new Button();
        button.transferOwnership(address(safe));
        module = new ButtonPushModule(address(timelock), address(button));

        safe.enableModule(address(timelock));
        safe.exec(
            payable(address(timelock)), 0, abi.encodeWithSelector(Modifier.enableModule.selector, address(module))
        );
    }

    function testShouldNotExecutePush() public {
        vm.expectRevert(TimelockModifier.TransactionsTimelocked.selector);
        module.pushButton();

        assertEq(button.pushes(), 0);
    }

    function testShouldExecutePush() public {
        vm.expectRevert(TimelockModifier.TransactionsTimelocked.selector);
        module.pushButton();
        assertEq(button.pushes(), 0);

        // warping past cooldown
        vm.warp(block.timestamp + cooldown + 1);

        // transaction correctly executed
        module.pushButton();
        assertEq(button.pushes(), 1);
    }
}
