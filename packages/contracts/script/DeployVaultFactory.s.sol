//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultFactory } from "../src/factories/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "../src/factories/CredbullUpsideVaultFactory.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployVaultFactory is Script {
    bool private test;

    using stdJson for string;

    bool private deployFixedYieldFactory;
    bool private deployUpsideFactory;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            HelperConfig helperConfig
        )
    {
        test = true;
        return run();
    }

    function run()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            HelperConfig helperConfig
        )
    {
        helperConfig = new HelperConfig(test);
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner;
        address operator;
        if (test) {
            owner = config.factoryParams.owner;
            operator = config.factoryParams.operator;
            deployFixedYieldFactory = true;
            deployUpsideFactory = true;
        } else {
            owner = vm.envAddress("PUBLIC_OWNER_ADDRESS");
            operator = vm.envAddress("PUBLIC_OPERATOR_ADDRESS");

            string memory root = vm.projectRoot();
            string memory path = string.concat(root, "/script/output/dbdata.json");

            if (vm.exists(path)) {
                string memory json = vm.readFile(path);

                bytes memory vaultFactory = json.parseRaw(".CredbullFixedYieldVaultFactory");
                bytes memory upsideVaultFactory = json.parseRaw(".CredbullUpsideVaultFactory");

                deployFixedYieldFactory = vaultFactory.length == 0;
                deployUpsideFactory = upsideVaultFactory.length == 0;
            } else {
                deployFixedYieldFactory = true;
                deployUpsideFactory = true;
            }
        }

        vm.startBroadcast();
        if (deployFixedYieldFactory) {
            factory = new CredbullFixedYieldVaultFactory(owner, operator);
            console2.log("!!!!! Deploying CredbullFixedYieldVaultFactory !!!!!");
        } else {
            console2.log("!!!!! Deployment skipped for CredbullFixedYieldVaultFactory !!!!!");
        }

        if (deployUpsideFactory) {
            upsideFactory = new CredbullUpsideVaultFactory(owner, operator);
            console2.log("!!!!! Deploying CredbullVaultWithUpsideFactory !!!!!");
        } else {
            console2.log("!!!!! Deployment skipped for CredbullVaultWithUpsideFactory !!!!!");
        }
        vm.stopBroadcast();

        return (factory, upsideFactory, helperConfig);
    }
}
