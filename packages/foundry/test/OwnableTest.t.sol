// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Vaults exchange Assets for Shares in the Vault
// see: https://eips.ethereum.org/EIPS/eip-4626
contract MyContract is Ownable {
    uint256 public number;

    constructor() Ownable(msg.sender) { }

    function setNumber(uint256 newNumber) public onlyOwner {
        number = newNumber;
    }

    function increment() public onlyOwner {
        number++;
    }

    function doNothing() public {
        // anyone can call this normalThing()
    }
}

// Test Cases to add:

contract CredbullMultiSigVaultTest is Test {
    MyContract myContract;

    function setUp() public {
        vm.startBroadcast();

        myContract = new MyContract();

        vm.stopBroadcast();
    }

    function testOwnerIsMsgSender() public {
        console.log("Token Owner", myContract.owner());

        assertEq(myContract.owner(), msg.sender);
    }

    function testOwnerCanSetNumber() public {
        uint256 number = 10;

        console.log("Token Owner", myContract.owner());
        console.log("Msg Sender", msg.sender);

        assertEq(myContract.owner(), msg.sender);

        vm.prank(msg.sender); // owner only call.  owner is  msg.sender.
        myContract.setNumber(number);

        assertEq(number, myContract.number());
    }

    // test some other user can't do specialThing
    function testNonOwnerThrowsError() public {
        address nonOwnerAddress = address(0x1);

        assertEq(myContract.owner(), msg.sender);

        vm.prank(nonOwnerAddress); // owner only call.  owner is  msg.sender.
        vm.expectRevert();
        myContract.setNumber(0);
    }
}
