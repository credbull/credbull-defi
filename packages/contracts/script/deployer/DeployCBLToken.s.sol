//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CBL } from "@credbull/token/CBL.sol";

import { ConfiguredToDeployCBL } from "./Configured.s.sol";

/// @notice The [Script] used to deploy the Credbull CBL Token Distribution.
contract DeployCBLToken is ConfiguredToDeployCBL {
    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull [$CBL] token.
     * @dev The return values are ignored, but included for test usages.
     *
     * @return cbl The deployed [CBL] token.
     */
    function run() external returns (CBL cbl) {
        address owner = owner();
        address minter = minter();
        uint256 maxSupply = maxSupply();

        vm.startBroadcast();
        cbl = new CBL(owner, minter, maxSupply);
        vm.stopBroadcast();

        return cbl;
    }
}
