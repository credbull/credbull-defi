//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { stdToml } from "forge-std/StdToml.sol";

import { CBL } from "../src/token/CBL.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";
import { TomlConfig } from "./TomlConfig.s.sol";

struct CBLTokenParams {
    address owner;
    address minter;
    uint256 maxSupply;
}

contract DeployCBLToken is TomlConfig {
    using stdToml for string;

    uint256 private constant PRECISION = 1e18;

    string private tomlConfig;
    bool private isTestMode;

    CBLTokenParams private cblTokenParams;

    constructor() {
        tomlConfig = loadTomlConfiguration();

        cblTokenParams = createCBLTokenParamsFromConfig();
    }

    function runTest() public returns (CBL cbl) {
        isTestMode = true;
        return run();
    }

    function run() public returns (CBL cbl) {
        CBLTokenParams memory params = createCBLTokenParamsFromConfig();

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CBL")) {
            cbl = new CBL(params.owner, params.minter, params.maxSupply);
        }

        vm.stopBroadcast();

        return cbl;
    }

    function getCBLTokenParams() public view returns (CBLTokenParams memory) {
        return cblTokenParams;
    }

    function createCBLTokenParamsFromConfig() internal view returns (CBLTokenParams memory) {
        CBLTokenParams memory tokenParams = CBLTokenParams({
            owner: tomlConfig.readAddress(".evm.contracts.cbl.owner"),
            minter: tomlConfig.readAddress(".evm.contracts.cbl.minter"),
            maxSupply: vm.parseUint(tomlConfig.readString(".evm.contracts.cbl.max_supply")) * PRECISION
        });

        return tokenParams;
    }
}
