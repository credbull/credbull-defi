// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { MockStablecoin } from "./MockStablecoin.sol";
import { DeployMockStablecoin } from "../../script/mocks/DeployMockStablecoin.s.sol";

contract MockStablecoinTest is Test {
    function testMockStablecoinOwnerOwnsAllTokens() public {
        address contractOwnerAddr = address(92385);

        DeployMockStablecoin deployMockStablecoin = new DeployMockStablecoin();
        MockStablecoin mockStablecoin = deployMockStablecoin.run(contractOwnerAddr);

        assertEq(mockStablecoin.owner(), contractOwnerAddr);

        uint256 totalSupply = mockStablecoin.totalSupply();
        assertEq(mockStablecoin.balanceOf(mockStablecoin.owner()), totalSupply);
    }
}
