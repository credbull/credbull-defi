//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { CBL } from "@credbull/token/CBL.sol";

import { CBLConfigured } from "./Configured.s.sol";

/// @notice The [Script] used to deploy the Credbull CBL Token Distribution.
contract DeployCBLToken is Script, CBLConfigured {
    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull [$CBL] token.
     * @dev The return values are ignored, but included for test usages.
     *
     * @return cbl The deployed [CBL] token.
     */
    function run() external returns (CBL cbl) {
        vm.startBroadcast();
        cbl = new CBL(owner(), minter(), maxSupply());
        vm.stopBroadcast();

        return cbl;
    }
}
