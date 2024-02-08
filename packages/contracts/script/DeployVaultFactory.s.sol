//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { CredbullVaultWithUpsideFactory } from "../src/upside/CredbullVaultWithUpsideFactory.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployVaultFactory is Script {
    bool private test;

    using stdJson for string;

    bool private deployFactory;
    bool private deployUpsideFactory;

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
            deployFactory = true;
            deployUpsideFactory = true;
        } else {
            owner = vm.envAddress("PUBLIC_OWNER_ADDRESS");
            operator = vm.envAddress("PUBLIC_OPERATOR_ADDRESS");

            string memory root = vm.projectRoot();
            string memory path = string.concat(root, "/script/output/dbdata.json");
            string memory json = vm.readFile(path);

            bytes memory vaultFactory = json.parseRaw(".CredbullVaultFactory");
            bytes memory upsideFactory = json.parseRaw(".CredbullVaultWithUpsideFactory");

            if (vaultFactory.length == 0) {
                deployFactory = true;
            }

            if (upsideFactory.length == 0) {
                deployUpsideFactory = true;
            }
        }

        vm.startBroadcast();
        if (deployFactory) {
            factory = new CredbullVaultFactory(owner, operator);
        } else {
            console2.log("!!!!! Deployment skipped for CredbullVaultFactory !!!!!");
        }

        if (deployUpsideFactory) {
            new CredbullVaultWithUpsideFactory(owner, operator, 20);
        } else {
            console2.log("!!!!! Deployment skipped for CredbullVaultWithUpsideFactory !!!!!");
        }
        vm.stopBroadcast();
    }
}
