//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { DeployCBLToken, CBLTokenParams } from "@script/DeployCBLToken.s.sol";
import { Script } from "forge-std/Script.sol";
import { TestToken } from "@test/test/token/TestToken.t.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployTestToken is Script {
    uint256 private constant PRECISION = 1e18;

    function run() public returns (TestToken testToken) {
        DeployCBLToken deployCBLToken = new DeployCBLToken();

        CBLTokenParams memory params = deployCBLToken.createCBLTokenParamsFromConfig();

        vm.startBroadcast();

        testToken = new TestToken(params.owner, params.minter, params.maxSupply);
        console2.log(string.concat("!!!!! Deploying TestToken [", vm.toString(address(testToken)), "] !!!!!"));
        vm.stopBroadcast();

        return testToken;
    }
}
