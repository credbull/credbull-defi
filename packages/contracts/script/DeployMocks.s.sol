//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";

import { console2 } from "forge-std/console2.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployMocks is Script {
    bool public isTestMode;
    uint128 public constant MAX_UINT128_SIZE = type(uint128).max;

    uint128 public totalSupply = MAX_UINT128_SIZE;

    constructor(bool _isTestMode) {
        isTestMode = _isTestMode;
    }

    function run() public returns (MockToken, MockStablecoin) {
        DeployedContracts deployChecker = new DeployedContracts();

        MockToken mockToken;
        MockStablecoin mockStablecoin;

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("MockToken")) {
            mockToken = new MockToken(totalSupply);
            console2.log("!!!!! Deploying MockToken !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("MockStablecoin")) {
            mockStablecoin = new MockStablecoin(totalSupply);
            console2.log("!!!!! Deploying MockStablecoin !!!!!");
        }

        vm.stopBroadcast();

        return (mockToken, mockStablecoin);
    }
}
