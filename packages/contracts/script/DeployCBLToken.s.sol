//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { CBL } from "../src/token/CBL.sol";
import { HelperConfig, TokenParams } from "./HelperConfig.s.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployCBLToken is Script {
    bool private isTestMode;

    function runTest() public returns (CBL clb, HelperConfig helperConfig) {
        isTestMode = true;
        return run();
    }

    function run() public returns (CBL cbl, HelperConfig helperConfig) {
        helperConfig = new HelperConfig(isTestMode);
        TokenParams memory params = helperConfig.getTokenParams();

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CBL")) {
            cbl = new CBL(params.owner, params.maxSupply);
        }

        vm.stopBroadcast();

        return (cbl, helperConfig);
    }
}
