//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultFactory } from "../src/factories/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "../src/factories/CredbullUpsideVaultFactory.sol";
import { CredbullKYCProvider } from "../src/CredbullKYCProvider.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployVaultFactory is Script {
    bool private isTestMode;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            CredbullKYCProvider kycProvider,
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
            CredbullKYCProvider kycProvider,
            HelperConfig helperConfig
        )
    {
        helperConfig = new HelperConfig(isTestMode);
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner = config.factoryParams.owner;
        address operator = config.factoryParams.operator;

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CredbullFixedYieldVaultFactory")) {
            factory = new CredbullFixedYieldVaultFactory(owner, operator);
            console2.log("!!!!! Deploying CredbullFixedYieldVaultFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullUpsideVaultFactory")) {
            upsideFactory = new CredbullUpsideVaultFactory(owner, operator);
            console2.log("!!!!! Deploying CredbullVaultWithUpsideFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullKYCProvider")) {
            kycProvider = new CredbullKYCProvider(operator);
            console2.log("!!!!! Deploying CredbullKYCProvider !!!!!");
        }

        vm.stopBroadcast();

        return (factory, upsideFactory, kycProvider, helperConfig);
    }
}
