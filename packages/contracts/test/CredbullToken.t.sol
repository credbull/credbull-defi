// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CredbullToken.sol";

contract CredbullTokenTest is Test {
    CredbullToken public credbullToken;
    uint256 public constant BASE_TOKEN_AMOUNT = 1000;

    function setUp() public {
        credbullToken = new CredbullToken(BASE_TOKEN_AMOUNT);
    }

    function testOwnerIsCredbullTokenTest() public {
        assertEq(credbullToken.owner(), address(this));
    }

    function testMintIncreasesSupply() public {
        assertEq(credbullToken.totalSupply(), BASE_TOKEN_AMOUNT); // start with the base amount

        credbullToken.mint(address(this), 1); // mint another 1

        assertEq(credbullToken.totalSupply(), BASE_TOKEN_AMOUNT + 1); // should should have added one
    }
}
