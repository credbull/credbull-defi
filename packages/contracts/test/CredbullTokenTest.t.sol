// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CredbullToken} from "../src/CredbullToken.sol";
import {DeployCredbullToken} from "../script/DeployCredbullToken.s.sol";

// TODO for Credbull Token and TEst
// 1. Make token Upgradeable
contract CredbullTokenTest is Test {
    CredbullToken public credbullToken;
    uint256 baseTokenAmount;

    function setUp() public {
        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();
        credbullToken = deployCredbullToken.run();

        baseTokenAmount = deployCredbullToken.BASE_TOKEN_AMOUNT();
    }

    function testDeploymentReturnsToken() public {
        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();

        assertTrue(address(deployCredbullToken.run()) != address(0x00));
    }

    function testOwnerIsMsgSender() public {
        assertEq(credbullToken.owner(), msg.sender);
    }

    function testMintIncreasesSupply() public {
        assertEq(credbullToken.totalSupply(), baseTokenAmount); // start with the base amount

        vm.prank(msg.sender); // owner only call.  owner is  msg.sender (see testOwnerIsCredbullTokenTest())
        credbullToken.mint(msg.sender, 1); // mint another 1

        assertEq(credbullToken.totalSupply(), baseTokenAmount + 1); // should should have added one
    }

    function testFailsWhenMintCalledByAddressThatIsntOwner() public {
        vm.prank(address(0x09)); // change msg sender to made up address
        credbullToken.mint(msg.sender, 1); // mint should fail, as owner only call
    }


}
