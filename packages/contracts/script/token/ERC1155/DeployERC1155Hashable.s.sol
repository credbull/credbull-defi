//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC1155Hashable } from "@credbull/token/ERC1155/ERC1155Hashable.sol";
import { TomlConfig, stdToml } from "@script/TomlConfig.s.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployERC1155Hashable is TomlConfig {
    using stdToml for string;

    string private _tomlConfig;

    constructor() {
        _tomlConfig = loadTomlConfiguration();
    }

    function run() public returns (ERC1155Hashable hashableToken) {
        address owner = roleFromConfig("owner");
        address minter = roleFromConfig("operator");

        return run(owner, minter);
    }

    function run(address owner, address minter) public returns (ERC1155Hashable hashableToken) {
        vm.startBroadcast();

        hashableToken = new ERC1155Hashable(owner, minter);
        console2.log(string.concat("!!!!! Deploying ERC1155Hashable [", vm.toString(address(hashableToken)), "] !!!!!"));
        vm.stopBroadcast();

        return hashableToken;
    }

    function roleFromConfig(string memory roleName) internal view returns (address role) {
        return _tomlConfig.readAddress(string.concat(".evm.address.", roleName));
    }
}
