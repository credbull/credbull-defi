// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CredbullToken} from "../contracts/CredbullToken.sol";

contract DeployCredbullToken is Script {
    uint256 public constant BASE_TOKEN_AMOUNT = 1000;

    function run() public returns (CredbullToken) {
        vm.startBroadcast();

        CredbullToken credbullToken = new CredbullToken(BASE_TOKEN_AMOUNT);

        vm.stopBroadcast();

        return credbullToken;
    }
}
