//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { CredbullVaultWithUpsideFactory } from "../src/upside/CredbullVaultWithUpsideFactory.sol";

contract DeployVaultFactory is Script {
    bool private test;

    function runTest() public returns (CredbullVaultFactory factory, HelperConfig helperConfig) {
        test = true;
        return run();
    }

    function run() public returns (CredbullVaultFactory factory, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner;
        address operator;
        if (test) {
            owner = config.factoryParams.owner;
            operator = config.factoryParams.operator;
        } else {
            owner = vm.envAddress("PUBLIC_OWNER_ADDRESS");
            operator = vm.envAddress("PUBLIC_OPERATOR_ADDRESS");
        }

        vm.startBroadcast();
        factory = new CredbullVaultFactory(owner, operator);
        new CredbullVaultWithUpsideFactory(owner, operator, 20);
        vm.stopBroadcast();
    }
}
