// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Vaults exchange Assets for Shares in the Vault
// see: https://eips.ethereum.org/EIPS/eip-4626
contract MyContract is Ownable {
    function normalThing() public {
        // anyone can call this normalThing()
    }

    function specialThing() public onlyOwner {
        // only the owner can call specialThing()!
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
}
