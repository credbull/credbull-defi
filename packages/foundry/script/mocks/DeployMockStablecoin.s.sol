// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../../test/mocks/MockStablecoin.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";

import { ScaffoldETHDeploy } from "../DeployHelpers.s.sol";

contract DeployMockStablecoin is ScaffoldETHDeploy {
    uint256 public constant BASE_TOKEN_AMOUNT = 50000;

    function run() public returns (MockStablecoin) {
        return run(msg.sender);
    }

    function run(address contractOwnerAddress) public returns (MockStablecoin) {
        vm.startBroadcast(contractOwnerAddress);

        MockStablecoin mockStablecoin = new MockStablecoin(
            BASE_TOKEN_AMOUNT
        );

        console.logString(string.concat("MockStablecoin deployed at: ", vm.toString(address(mockStablecoin))));

        vm.stopBroadcast();

        exportDeployments(); // generates file with Abi's.  call this last.

        return mockStablecoin;
    }
}
