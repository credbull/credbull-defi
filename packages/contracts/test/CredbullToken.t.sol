// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/CredbullToken.sol";

contract CredbullTokenTest is Test {
    CredbullToken public credbullToken;
    uint256 tokensToMint = 1000;

    function setUp() public {
        credbullToken = new CredbullToken(tokensToMint);
    }

    function testMinted() public {
        assertEq(credbullToken.totalSupply(), tokensToMint);
    }
}
