// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { stdToml } from "forge-std/StdToml.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";

import { TomlConfig } from "../TomlConfig.s.sol";

abstract contract Deployer is TomlConfig {
    using stdToml for string;

    function deployTo(string memory network) internal {
        string memory config = loadTomlConfiguration();
        string memory root = string.concat(".network.", network);

        deployVaultFactories(root, config);

        // Support Contracts
        bool deploySupportContracts = config.readBool(string.concat(root, ".deploy_mocks"));
    }

    function deployVaultFactories(string memory root, string memory config) private {
        string memory addresses = string.concat(root, ".deployment.vault_factory.actors.address");
        address owner = config.readAddress(string.concat(addresses, ".owner"));
        address operator = config.readAddress(string.concat(addresses, ".operator"));
        address[] memory custodians = new address[](1);
        custodians[0] = config.readAddress(string.concat(addresses, ".custodian"));

        vm.startBroadcast();
        new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        new CredbullUpsideVaultFactory(owner, operator, custodians);
        new CredbullWhiteListProvider(operator);
        vm.stopBroadcast();
    }
}

contract Arbitrum is Deployer {
    function run() external {
        deployTo("Arbitrum");
    }

    // NOTE (JL,2024-07-16): Arbitrum specific steps here.
}

contract BaseSepolia is Deployer {
    function run() external {
        deployTo("BaseSepolia");
    }
}
