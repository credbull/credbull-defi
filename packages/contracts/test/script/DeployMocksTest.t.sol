//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { DeployMockToken, DeployMockStablecoin } from "../../script/DeployMocks.s.sol";

contract DeployMocksTest is Test {
    function test__DeployMocksTest__DeployMockToken() public {
        DeployMockToken deployToken = new DeployMockToken();
        assertNotEq(address(0), address(deployToken.run()));

        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();
        assertNotEq(address(0), address(deployStablecoin.run()));
    }
}
