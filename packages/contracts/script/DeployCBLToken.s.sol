//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { CBL } from "@credbull/token/CBL.sol";

import { CBLConfig } from "./TomlConfig.s.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

/// @notice The [Script] used to deploy the Credbull CBL Token Distribution.
contract DeployCBLToken is Script, CBLConfig {
    /// @dev Whether to skip the deployment check, or not. By default, do not skip.
    bool private _skipDeployCheck = false;

    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull [$CBL] token, if
     * @dev The return values are ignored, but included for test usages.
     *
     * @return cbl The deployed [CBL] token, if any.
     */
    function run() external returns (CBL cbl) {
        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();
        if (_skipDeployCheck || deployChecker.isDeployRequired("CBL")) {
            cbl = new CBL(owner(), minter(), maxSupply());
        }
        vm.stopBroadcast();

        return cbl;
    }

    /// @dev A Fluent API mutator that disable the Deployment Check and returns [this] [DeployCBLToken].
    function skipDeployCheck() public returns (DeployCBLToken) {
        _skipDeployCheck = true;
        return this;
    }
}
