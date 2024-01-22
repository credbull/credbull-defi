//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullEntities } from "../src/CredbullEntities.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";

contract DeployVaultFactory is Script {
    function run() public returns (CredbullVaultFactory factory, HelperConfig helperConfig) {
        helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        this.deployCredbullEntities(config.entities);

        vm.startBroadcast();
        factory = new CredbullVaultFactory(config.vaultParams.owner);
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
