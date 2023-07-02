// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CredbullToken} from "../src/CredbullToken.sol";

contract DeployCredbullToken is Script {
    function run() public returns (CredbullToken) {
        vm.startBroadcast();

        CredbullToken credbullToken = new CredbullToken(1000);

        vm.stopBroadcast();

        return credbullToken;
    }
}
