// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/test/Button.sol";
import "../src/test/ButtonPushModule.sol";
import {Enum} from "@gnosis.pm/zodiac/contracts/core/Modifier.sol";
import "zodiac-modifier-roles/Roles.sol";
import {TestAvatar} from "zodiac/test/TestAvatar.sol";

contract RolesTest is Test {

    TestAvatar private safe;
    Button private button;
    ButtonPushModule private module;
    Roles private roles;
    bytes32 ROLE_ID = keccak256("0x0000000000000000000000000000000000000000000000000000000000000001");

    function setUp() public {
        safe = new TestAvatar();
        roles = new Roles(address(safe), address(safe), address(safe));

        button = new Button();
        button.transferOwnership(address(safe));
        module = new ButtonPushModule(address(roles), address(button));

        safe.enableModule(address(roles));
    }

    function testShouldExecutePush() public {
        bytes32[] memory rolesToAssign = new bytes32[](1);
        rolesToAssign[0] = ROLE_ID;
        bool[] memory allowed = new bool[](1);
        allowed[0] = true;

        vm.startPrank(address(safe));

        roles.assignRoles(address(module), rolesToAssign, allowed);
        roles.setDefaultRole(address(module), rolesToAssign[0]);

        roles.scopeTarget(ROLE_ID, address(button));
        roles.allowFunction(ROLE_ID, address(button), Button.pushButton.selector, ExecutionOptions.None);

        vm.stopPrank();

        module.pushButton();
        assertEq(button.pushes(), 1);
    }
}
