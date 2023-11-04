// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { CredbullToken } from "../contracts/CredbullToken.sol";
import { ScaffoldETHDeploy } from "./DeployHelpers.s.sol";

import { console } from "forge-std/console.sol";

contract DeployCredbullToken is ScaffoldETHDeploy {
    uint256 public constant BASE_TOKEN_AMOUNT = 1000;

    error InvalidPrivateKey(string);

    function run() public returns (CredbullToken) {
        return run(msg.sender);
    }

    function run(address contractOwnerAddress) public returns (CredbullToken) {
        vm.startBroadcast(contractOwnerAddress);

        CredbullToken credbullToken = new CredbullToken(contractOwnerAddress, BASE_TOKEN_AMOUNT);

        console.logString(string.concat("CredbullToken deployed at: ", vm.toString(address(credbullToken))));

        vm.stopBroadcast();

        exportDeployments(); // generates file with Abi's.  call this last.

        return credbullToken;
    }
}
