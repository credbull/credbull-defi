//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullEntities } from "../src/CredbullEntities.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployVaultFactory is Script {
    bool test;

    function runTest() public returns (CredbullVaultFactory factory, HelperConfig helperConfig) {
        test = true;
        return run();
    }

    function run() public returns (CredbullVaultFactory factory, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        this.deployCredbullEntities(config.entities);

        address owner;
        if (test) {
            owner = config.vaultParams.owner;
        } else {
            owner = vm.envAddress("PUBLIC_OWNER_ADDRESS");
        }

        vm.startBroadcast();
        factory = new CredbullVaultFactory(owner);
        vm.stopBroadcast();
    }

    function deployCredbullEntities(ICredbull.Entities memory config) external returns (CredbullEntities) {
        vm.startBroadcast();
        CredbullEntities entities =
            new CredbullEntities(config.custodian, config.kycProvider, config.treasury, config.activityReward);
        vm.stopBroadcast();

        return entities;
    }
}
