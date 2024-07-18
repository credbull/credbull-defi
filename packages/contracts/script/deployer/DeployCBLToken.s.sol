//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CBL } from "@credbull/token/CBL.sol";

import { ConfiguredToDeployCBL } from "./Configured.s.sol";

contract DeployCBLToken is ConfiguredToDeployCBL {
    function run() internal returns (CBL cbl) {
        address owner = owner();
        address minter = minter();
        uint256 maxSupply = maxSupply();

        vm.startBroadcast();
        cbl = new CBL(owner, minter, maxSupply);
        vm.stopBroadcast();

        return cbl;
    }
}
