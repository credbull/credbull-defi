//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CBL } from "../../src/token/CBL.sol";
import { DeployCBLToken, CBLTokenParams } from "../../script/DeployCBLToken.s.sol";

contract CBLTest is Test {
    CBL private cbl;
    DeployCBLToken private deployCBLToken;
    CBLTokenParams private cblTokenParams;

    address private alice = makeAddr("alice");
    address private owner;
    address private minter;

    function setUp() public {
        deployCBLToken = new DeployCBLToken();
        cblTokenParams = deployCBLToken.getCBLTokenParams();
        owner = cblTokenParams.owner;
        minter = cblTokenParams.minter;
        cbl = deployCBLToken.runTest();
    }

    function test__CBL__SuccessfullyDeployCBLToken() public {
        cbl = new CBL(cblTokenParams.owner, cblTokenParams.minter, cblTokenParams.maxSupply);
        assertTrue(cbl.hasRole(cbl.DEFAULT_ADMIN_ROLE(), cblTokenParams.owner));
        assertTrue(cbl.hasRole(cbl.MINTER_ROLE(), cblTokenParams.minter));
        assertEq(cbl.maxSupply(), cblTokenParams.maxSupply);
    }

    function test__CBL__ShouldAllowMinterToMint() public {
        vm.prank(minter);
        cbl.mint(alice, 100);
    }

    function test__CBL__ShouldRevertIfNotMinterMint() public {
        vm.prank(alice);
        vm.expectRevert();
        cbl.mint(alice, 100);
    }

    function test__CBL__ShouldAllowMinterToBurn() public {
        vm.startPrank(minter);
        cbl.mint(minter, 100);
        cbl.burn(100);
        vm.stopPrank();
    }

    function test__CBL__ShouldAllowUserToBurn() public {
        vm.prank(minter);
        cbl.mint(alice, 100);

        vm.prank(alice);
        cbl.burn(100);
    }

    function test__CBL__ShouldRevertIfTotalSupplyExceedsMaxSupply() public {
        vm.startPrank(minter);
        cbl.mint(minter, cbl.maxSupply());

        vm.expectRevert(CBL.CBL__MaxSupplyExceeded.selector);
        cbl.mint(minter, 1);
        vm.stopPrank();
    }

    function test__CBL__ShouldReturnCorrectTotalSupply() public {
        vm.prank(minter);
        cbl.mint(minter, 100);
        assertEq(cbl.totalSupply(), 100);
    }
}
