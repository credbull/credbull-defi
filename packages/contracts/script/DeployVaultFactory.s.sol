//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";

import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployVaultFactory is Script {
    bool private isTestMode;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            CredbullWhiteListProvider whiteListProvider,
            HelperConfig helperConfig
        )
    {
        isTestMode = true;
        return run();
    }

    function run()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            CredbullWhiteListProvider whiteListProvider,
            HelperConfig helperConfig
        )
    {
        helperConfig = new HelperConfig(isTestMode);
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner = config.factoryParams.owner;
        address operator = config.factoryParams.operator;
        address[] memory custodians = new address[](1);
        custodians[0] = config.factoryParams.custodian;

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CredbullFixedYieldVaultFactory")) {
            factory = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
            console2.log("!!!!! Deploying CredbullFixedYieldVaultFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullUpsideVaultFactory")) {
            upsideFactory = new CredbullUpsideVaultFactory(owner, operator, custodians);
            console2.log("!!!!! Deploying CredbullVaultWithUpsideFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullWhiteListProvider")) {
            whiteListProvider = new CredbullWhiteListProvider(operator);
            console2.log("!!!!! Deploying CredbullWhiteListProvider !!!!!");
        }

        vm.stopBroadcast();

        return (factory, upsideFactory, whiteListProvider, helperConfig);
    }
}
