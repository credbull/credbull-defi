// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CredbullToken} from "../contracts/CredbullToken.sol";
import {DeployCredbullToken} from "../script/DeployCredbullToken.s.sol";

// TODO for Credbull Token and Test
// 1. Make token Upgradeable
contract CredbullTokenTest is Test {
    CredbullToken public credbullToken;
    uint256 baseTokenAmount;
    address contractOwnerAddr;

    function setUp() public {
        contractOwnerAddr = msg.sender;

        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();
        credbullToken = deployCredbullToken.run(contractOwnerAddr);

        baseTokenAmount = deployCredbullToken.BASE_TOKEN_AMOUNT();
    }

    function testDeployTokenReturnsToken() public {
        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();

        assertTrue(address(deployCredbullToken.run(contractOwnerAddr)) != address(0));
    }

    function testOwnerIsMsgSender() public {
        assertEq(credbullToken.owner(), contractOwnerAddr);
    }

    function testOwnerOwnsAllTokens() public {
        assertEq(credbullToken.owner(), contractOwnerAddr);

        uint256 totalSupply = credbullToken.totalSupply();
        assertEq(credbullToken.balanceOf(credbullToken.owner()), totalSupply);
    }

    function testMintIncreasesSupply() public {
        assertEq(credbullToken.totalSupply(), baseTokenAmount); // start with the base amount

        vm.prank(contractOwnerAddr); // owner only call.  owner is  msg.sender.
        credbullToken.mint(contractOwnerAddr, 1); // mint another 1

        assertEq(credbullToken.totalSupply(), baseTokenAmount + 1); // should should have added one
    }

    function testFailsWhenMintCalledByAddressThatIsntOwner() public {
        vm.prank(address(9)); // change msg sender to made up address
        credbullToken.mint(contractOwnerAddr, 1); // mint should fail, as owner only call
    }

    function testTransferToAliceAndWithdraw() public {
        assertEq(credbullToken.owner(), contractOwnerAddr);

        address alice = makeAddr("alice");
        assertEq(credbullToken.balanceOf(alice), 0);

        uint256 transferAmount = 10;

        vm.prank(contractOwnerAddr);
        credbullToken.transfer(alice, transferAmount);
        assertEq(credbullToken.balanceOf(alice), transferAmount);
    }

}
