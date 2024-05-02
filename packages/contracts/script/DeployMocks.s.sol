//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { console2 } from "forge-std/console2.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";
import { ConditionalDeploy } from "./ConditionalDeploy.s.sol";

/// @title Deploy the MockToken contract
contract DeployMockToken is ConditionalDeploy {
    string public constant MOCK_TOKEN = "MockToken";

    constructor() ConditionalDeploy(MOCK_TOKEN) { }

    function run() public returns (MockToken) {
        vm.startBroadcast();
        MockToken token = new MockToken(type(uint128).max);
        console2.log("!!!!! Deploying ", MOCK_TOKEN, "!!!!!");
        vm.stopBroadcast();

        return token;
    }

    function deployAlways() public override returns (address) {
        return address(run());
    }
}

/// @title Deploy the MockStablCoin contract.
contract DeployMockStablecoin is ConditionalDeploy {
    string public constant MOCK_STABLECOIN = "MockStablecoin";

    constructor() ConditionalDeploy(MOCK_STABLECOIN) { }

    function run() public returns (MockStablecoin) {
        vm.startBroadcast();
        MockStablecoin usdc = new MockStablecoin(type(uint128).max);
        console2.log("!!!!! Deploying MockStablecoin !!!!!");
        vm.stopBroadcast();

        return usdc;
    }

    function deployAlways() public override returns (address) {
        return address(run());
    }
}
