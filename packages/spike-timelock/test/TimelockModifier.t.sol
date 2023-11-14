// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TimelockModifier.sol";
import "../src/test/Vault.sol";
import "../src/test/VaultModule.sol";
import "../src/test/SimpleToken.sol";
import { TestAvatar } from "zodiac/test/TestAvatar.sol";
import { Enum } from "@gnosis.pm/zodiac/contracts/core/Modifier.sol";

contract TimelockModifierTest is Test {
    uint64 private cooldown = 180;

    SimpleToken public token;
    TestAvatar private safe;
    Vault private vault;
    VaultModule private module;
    TimelockModifier private timelock;

    function setUp() public {
        token = new SimpleToken(1000);
        safe = new TestAvatar();

        vault = new Vault(token, "Vault", "xVault");
        vault.transferOwnership(address(safe));

        timelock = new TimelockModifier(
            address(safe), address(safe), uint64(block.timestamp), uint64(block.timestamp) + cooldown
        );
        safe.enableModule(address(timelock));

        module = new VaultModule(address(timelock), address(vault));
        timelock.enableModule(address(module));
        timelock.transferOwnership(address(safe));
    }

    function testShouldNotExecuteWithdraw() public {
        address john = makeAddr("John");
        token.mint(john, 1000);

        vm.startPrank(john);
        token.approve(address(vault), 1000);
        vault.deposit(1000, john);

        vm.expectRevert(TimelockModifier.TransactionsTimelocked.selector);
        module.withdraw(1000, john, john);
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), 1000);
        assertEq(token.balanceOf(address(john)), 0);
        assertEq(vault.balanceOf(address(john)), 1000);
    }

    function testShouldExecuteWithdraw() public {
        address john = makeAddr("John");
        token.mint(john, 1000);

        vm.startPrank(john);
        token.approve(address(vault), 1000);
        vault.deposit(1000, john);

        // warping past cooldown
        vm.warp(block.timestamp + cooldown + 1);

        vault.approve(address(safe), 1000);
        module.withdraw(1000, john, john);
        vm.stopPrank();

        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(address(john)), 1000);
        assertEq(vault.balanceOf(address(john)), 0);
    }
}
