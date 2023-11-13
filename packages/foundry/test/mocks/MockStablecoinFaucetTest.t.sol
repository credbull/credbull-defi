// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { MockStablecoin } from "./MockStablecoin.sol";
import { DeployMockStablecoin } from "../../script/mocks/DeployMockStablecoin.s.sol";
import "../../script/mocks/DeployMockStablecoinFaucet.s.sol";

contract MockStablecoinFaucetTest is Test {

    MockStablecoin public mockStablecoin;
    MockStablecoinFaucet public faucet;

    address public contractOwnerAddr;

    function setUp() public {
        contractOwnerAddr = msg.sender;

        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();
        mockStablecoin = deployStablecoin.run(contractOwnerAddr);

        DeployMockStablecoinFaucet deployFaucet = new DeployMockStablecoinFaucet();
        faucet = deployFaucet.run(contractOwnerAddr, mockStablecoin);
    }


    function testFaucetCanGiveTokens() public {
        address john = makeAddr("john");

        vm.startPrank(john);
        faucet.give(100);
        vm.stopPrank();

        assertEq(mockStablecoin.balanceOf(john), 100);
    }
}
