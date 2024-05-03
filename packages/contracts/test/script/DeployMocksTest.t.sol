//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { DeployMocks } from "../../script/DeployMocks.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";

contract DeployMocksTest is Test {
    function test__DeployMocksTest__DeployMockToken() public {
        DeployMocks deployMocks = new DeployMocks(true);
        (MockToken mockToken, MockStablecoin mockStablecoin) = deployMocks.run();

        assertNotEq(address(0), address(mockToken));
        assertNotEq(address(0), address(mockStablecoin));

        assertEq(deployMocks.totalSupply(), mockToken.totalSupply());
        assertEq(deployMocks.totalSupply(), mockStablecoin.totalSupply());
    }
}
