//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";

/// @notice Any script that is based upon the multi-network syntax TOML Configuration should extend this.
abstract contract Configured is Script {
    using stdToml for string;

    uint256 internal constant PRECISION = 1e18;
    string internal constant ROOT = ".network.";
    string internal constant DEPLOYMENT = ".deployment";

    string internal config;

    constructor() {
        config = load();
    }

    function load() private view returns (string memory) {
        string memory environment = vm.envString("ENVIRONMENT");
        string memory path = string.concat(vm.projectRoot(), "/resource/", environment, ".toml");
        console2.log(string.concat("Loading TOML configuration from: ", path));
        return vm.readFile(path);
    }
}

abstract contract VaultFactoryConfigured is Configured {
    using stdToml for string;

    function doDeploySupportContracts(string memory network) internal view returns (bool) {
        return config.readBool(string.concat(ROOT, network, DEPLOYMENT, ".support.deploy"));
    }

    function vaultFactoryOwner(string memory network) internal view returns (address) {
        return config.readAddress(string.concat(ROOT, network, DEPLOYMENT, ".vault_factory.address.owner"));
    }

    function vaultFactoryOperator(string memory network) internal view returns (address) {
        return config.readAddress(string.concat(ROOT, network, DEPLOYMENT, ".vault_factory.address.operator"));
    }

    function vaultFactoryCustodian(string memory network) internal view returns (address) {
        return config.readAddress(string.concat(ROOT, network, DEPLOYMENT, ".vault_factory.address.custodian"));
    }
}

abstract contract TokenConfigured is Configured {
    using stdToml for string;

    function tokenMaxSupply(string memory network) internal view returns (uint256) {
        return config.readUint(string.concat(ROOT, network, DEPLOYMENT, ".token.cbl.max_supply")) * PRECISION;
    }

    function tokenOwner(string memory network) internal view returns (address) {
        return config.readAddress(string.concat(ROOT, network, DEPLOYMENT, ".token.cbl.address.owner"));
    }

    function tokenMinter(string memory network) internal view returns (address) {
        return config.readAddress(string.concat(ROOT, network, DEPLOYMENT, ".token.cbl.address.minter"));
    }
}
