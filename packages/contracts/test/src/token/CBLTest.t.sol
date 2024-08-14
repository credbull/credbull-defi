//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { CBL } from "@credbull/token/CBL.sol";

import { DeployCBLToken } from "@script/DeployCBLToken.s.sol";
import { CBLConfig } from "@script/TomlConfig.s.sol";

contract CBLTest is Test, CBLConfig {
    DeployCBLToken private deployer;

    CBL private cbl;

    address private alice = makeAddr("alice");

    function setUp() public {
        deployer = new DeployCBLToken().skipDeployCheck();

        cbl = deployer.run();
    }

    function test__CBL__ShouldRevertOnZeroAddress() public {
        vm.expectRevert(CBL.CBL__InvalidOwnerAddress.selector);
        new CBL(address(0), makeAddr("minter"), type(uint32).max);

        vm.expectRevert(CBL.CBL__InvalidMinterAddress.selector);
        new CBL(makeAddr("owner"), address(0), type(uint32).max);
    }

    function test__CBL__SuccessfullyDeployCBLToken() public {
        cbl = new CBL(owner(), minter(), maxSupply());
        assertTrue(cbl.hasRole(cbl.DEFAULT_ADMIN_ROLE(), owner()));
        assertTrue(cbl.hasRole(cbl.MINTER_ROLE(), minter()));
        assertEq(cbl.cap(), maxSupply());
    }

    function test__CBL__ShouldAllowMinterToMint() public {
        vm.prank(minter());
        cbl.mint(alice, 100);
    }

    function test__CBL__ShouldRevertIfNotMinterMint() public {
        vm.prank(alice);
        vm.expectRevert();
        cbl.mint(alice, 100);
    }

    function test__CBL__ShouldAllowMinterToBurn() public {
        vm.startPrank(minter());
        cbl.mint(minter(), 100);
        cbl.burn(100);
        vm.stopPrank();
    }

    function test__CBL__ShouldAllowUserToBurn() public {
        vm.prank(minter());
        cbl.mint(alice, 100);

        vm.prank(alice);
        cbl.burn(100);
    }

    function test__CBL__ShouldRevertIfTotalSupplyExceedsMaxSupply() public {
        vm.startPrank(minter());
        cbl.mint(minter(), cbl.cap());

        vm.expectRevert(abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, cbl.totalSupply() + 1, cbl.cap()));
        cbl.mint(minter(), 1);
        vm.stopPrank();
    }

    function test__CBL__ShouldReturnCorrectTotalSupply() public {
        vm.prank(minter());
        cbl.mint(minter(), 100);
        assertEq(cbl.totalSupply(), 100);
    }

    function test__CBL__PauseAndUnPauseMintAndBurn() public {
        vm.prank(minter());
        cbl.mint(alice, 100);

        vm.prank(owner());
        cbl.pause();

        vm.prank(minter());
        vm.expectRevert(Pausable.EnforcedPause.selector);
        cbl.mint(alice, 100);

        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        cbl.burn(100);

        vm.prank(owner());
        cbl.unpause();

        vm.prank(minter());
        cbl.mint(alice, 100);

        vm.prank(alice);
        cbl.burn(100);
    }
}
