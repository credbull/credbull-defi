// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CredbullToken} from "../contracts/CredbullToken.sol";

import {console} from "forge-std/console.sol";

contract DeployCredbullToken is Script {
    uint256 public constant BASE_TOKEN_AMOUNT = 1000;

    function createCredbullToken() public returns (CredbullToken) {
        CredbullToken credbullToken = new CredbullToken(BASE_TOKEN_AMOUNT);

        console.logString(string.concat("CredbullToken deployed at: ", vm.toString(address(credbullToken))));

        return credbullToken;
    }

    function deployCredbullToken() public returns (CredbullToken) {
        vm.startBroadcast();

        CredbullToken credbullToken = createCredbullToken();

        vm.stopBroadcast();

        return credbullToken;
    }
}
