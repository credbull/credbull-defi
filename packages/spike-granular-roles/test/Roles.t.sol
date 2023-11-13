// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/test/MockSafe.sol";
import "../src/test/Button.sol";
import "../src/test/ButtonPushModule.sol";
import {Enum} from "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "zodiac-modifier-roles/Roles.sol";

contract RolesTest is Test {


    MockSafe private safe;
    Button private button;
    ButtonPushModule private module;
    Roles private roles;
    bytes32 ROLE_ID = keccak256("0x000000000000000000000000000000000000000000000000000000000000000f");

    function setUp() public {
        safe = new MockSafe();
        roles = new Roles(address(safe), address(safe), address(safe));

        button = new Button();
        button.transferOwnership(address(safe));
        module = new ButtonPushModule(address(roles), address(button));

        safe.enableModule(address(roles));
        safe.exec(payable(address(roles)), 0, abi.encodeWithSelector(Modifier.enableModule.selector, address(module)));
    }

    function testShouldExecutePush() public {
        roles.allowTarget(ROLE_ID, address(button), ExecutionOptions.None);

        bytes32[] memory rolesToAssign = new bytes32[](1);
        rolesToAssign[0] = ROLE_ID;

        bool[] memory allowed = new bool[](1);
        allowed[0] = true;

        roles.assignRoles(address(module), rolesToAssign, allowed);


        address invoker = makeAddr("invoker");
        vm.startPrank(invoker);

        module.pushButton();
        assertEq(button.pushes(), 1);

        vm.stopPrank();
    }
}
