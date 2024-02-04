//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullEntities } from "../src/CredbullEntities.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "../src/CredbullUpsideVaultFactory.sol";
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
        CredbullUpsideVaultFactory upsideFactory = new CredbullUpsideVaultFactory(owner, operator);
        console2.log("CredbullUpsideVaultFactory: ", address(upsideFactory));
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
