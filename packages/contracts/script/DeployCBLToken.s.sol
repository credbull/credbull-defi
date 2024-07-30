//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { CBL } from "@credbull/token/CBL.sol";

import { CBLConfigured } from "./Configured.s.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

/// @notice The [Script] used to deploy the Credbull CBL Token Distribution.
contract DeployCBLToken is Script, CBLConfigured {
    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull [$CBL] token, if
     * @dev The return values are ignored, but included for test usages.
     *
     * @return cbl The deployed [CBL] token, if any.
     */
    function run() external returns (CBL) {
        return deploy(false);
    }

    /**
     * @dev Deploys the CBL Distribution Unit, if deployment is possible.
     *
     * @param skipDeployCheck A [bool] flag determining whether to check if deployment is possible or not.
     *
     * @return cbl The deployed [CBL].
     */
    function deploy(bool skipDeployCheck) public returns (CBL cbl) {
        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();
        if (skipDeployCheck || deployChecker.isDeployRequired("CBL")) {
            cbl = new CBL(owner(), minter(), maxSupply());
        }
        vm.stopBroadcast();

        return cbl;
    }
}
