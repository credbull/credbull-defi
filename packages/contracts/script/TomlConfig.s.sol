//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";

/// @title Helper to centralize any Toml configuration functions
abstract contract TomlConfig is Script {
    using stdToml for string;

    function loadTomlConfiguration() internal view returns (string memory) {
        string memory environment = vm.envString("ENVIRONMENT");
        string memory path = string.concat(vm.projectRoot(), "/resource/", environment, ".toml");
        console2.log(string.concat("Loading toml configuration from: ", path));
        return vm.readFile(path);
    }

    function _readUintWithDefault(string memory tomlConfig, string memory tomlKey, uint256 defaultValue)
        internal
        view
        returns (uint256 value)
    {
        if (!vm.keyExistsToml(tomlConfig, tomlKey)) return defaultValue;

        return tomlConfig.readUint(tomlKey);
    }

    function _readBoolWithDefault(string memory tomlConfig, string memory tomlKey, bool defaultValue)
        internal
        view
        returns (bool value)
    {
        if (!vm.keyExistsToml(tomlConfig, tomlKey)) return defaultValue;

        return tomlConfig.readBool(tomlKey);
    }
}
