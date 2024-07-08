//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CBL } from "../../src/token/CBL.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { DeployCBLToken } from "../../script/DeployCBLToken.s.sol";

contract CBLTest is Test {
    CBL private cbl;
    HelperConfig private helperConfig;
    address private alice = makeAddr("alice");
    address private owner;
    address private minter;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function setUp() public {
        (cbl, helperConfig) = new DeployCBLToken().runTest();
        owner = helperConfig.getTokenParams().owner;
        minter = helperConfig.getTokenParams().minter;
    }

    function test__CBL__SuccessfullyDeployCBLToken() public {
        uint256 maxSupply = helperConfig.getTokenParams().maxSupply;
        cbl = new CBL(owner, minter, maxSupply);
        assertTrue(cbl.hasRole(cbl.DEFAULT_ADMIN_ROLE(), owner));
        assertTrue(cbl.hasRole(cbl.MINTER_ROLE(), minter));
        assertEq(cbl.maxSupply(), maxSupply);
    }

    function test__CBL__ShouldAllowOwnerToMint() public {
        vm.prank(owner);
        cbl.mint(alice, 100);
    }

    function test__CBL__ShouldRevertIfNotOwnerMint() public {
        vm.prank(alice);
        vm.expectRevert();
        cbl.mint(alice, 100);
    }

    function test__CBL__ShouldAllowOwnerToBurn() public {
        vm.startPrank(owner);
        cbl.mint(owner, 100);
        cbl.burn(100);
        vm.stopPrank();
    }

    function test__CBL__ShouldAllowNonOwnerToBurn() public {
        vm.prank(owner);
        cbl.mint(alice, 100);

        vm.prank(alice);
        cbl.burn(100);
    }

    function test__CBL__ShouldRevertIfTotalSupplyExceedsMaxSupply() public {
        vm.startPrank(owner);
        cbl.mint(owner, cbl.maxSupply());

        vm.expectRevert(CBL.CBL__MaxSupplyExceeded.selector);
        cbl.mint(owner, 1);
        vm.stopPrank();
    }

    function test__CBL__ShouldReturnCorrectTotalSupply() public {
        vm.prank(owner);
        cbl.mint(owner, 100);
        assertEq(cbl.totalSupply(), 100);
    }
}
