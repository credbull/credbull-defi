//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";
import { StdChains } from "forge-std/StdChains.sol";

/// @notice Any script that is based upon the multi-network syntax TOML Configuration should extend this.
abstract contract Configured is StdChains, Script {
    using stdToml for string;

    string internal config;
    Chain internal chain;

    constructor() {
        config = load();
        chain = getChain(block.chainid);
    }

    function load() private view returns (string memory) {
        string memory environment = vm.envString("ENVIRONMENT");
        string memory path = string.concat(vm.projectRoot(), "/resource/", environment, ".toml");
        console2.log(string.concat("Loading TOML configuration from: ", path));
        return vm.readFile(path);
    }
}

abstract contract ConfiguredToDeployVaults is Configured {
    using stdToml for string;

    function owner() internal view returns (address) {
        return config.readAddress(".deployment.vaults.address.owner");
    }

    function operator() internal view returns (address) {
        return config.readAddress(".deployment.vaults.address.operator");
    }

    function custodian() internal view returns (address) {
        return config.readAddress(".deployment.vaults.address.custodian");
    }
}

abstract contract ConfiguredToDeployVaultsSupport is ConfiguredToDeployVaults {
    using stdToml for string;

    function deploySupport() internal view returns (bool) {
        return config.readBool(".deployment.support.deploy");
    }
}

abstract contract ConfiguredToDeployCBL is Configured {
    using stdToml for string;

    uint256 internal constant PRECISION = 1e18;

    function maxSupply() internal view returns (uint256) {
        return config.readUint(".deployment.token.cbl.max_supply") * PRECISION;
    }

    function owner() internal view returns (address) {
        return config.readAddress(".deployment.token.cbl.address.owner");
    }

    function minter() internal view returns (address) {
        return config.readAddress(".deployment.token.cbl.address.minter");
    }
}
