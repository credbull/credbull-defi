// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { MockStablecoin } from "./MockStablecoin.sol";
import { DeployMockStablecoin } from "../../script/mocks/DeployMockStablecoin.s.sol";

contract MockStablecoinFaucetTest is Test {

    MockStablecoin public mockStablecoin;

    address public contractOwnerAddr;

    function setUp() public {
        contractOwnerAddr = msg.sender;

        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();
        mockStablecoin = deployStablecoin.run(contractOwnerAddr);
    }


    function testFaucetCanGiveTokens() public {
        uint amountToGive = 100;
        address john = makeAddr("john");

        uint totalSupplyBefore = mockStablecoin.totalSupply();

        vm.startPrank(john);
        mockStablecoin.give(amountToGive);
        vm.stopPrank();

        uint totalSupplyAfter = mockStablecoin.totalSupply();

        assertEq(mockStablecoin.balanceOf(john), amountToGive);
        assertEq(totalSupplyAfter, totalSupplyBefore + amountToGive);
    }
}
