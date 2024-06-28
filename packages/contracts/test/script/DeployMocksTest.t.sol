//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { DeployMocks } from "@script/DeployMocks.s.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

contract DeployMocksTest is Test, DeployMocks {
    constructor() DeployMocks(true, makeAddr("custodian")) { }

    function test__DeployMocksTest__DeployMocks() public {
        (SimpleToken testToken, SimpleUSDC testStablecoin) = run();

        assertNotEq(address(0), address(testToken));
        assertNotEq(address(0), address(testStablecoin));
        assertNotEq(address(0), address(testVault));

        assertEq(totalSupply, testToken.totalSupply());
        assertEq(totalSupply, testStablecoin.totalSupply());
    }
}
