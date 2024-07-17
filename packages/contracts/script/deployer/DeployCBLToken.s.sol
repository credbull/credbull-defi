//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { stdToml } from "forge-std/StdToml.sol";

import { CBL } from "@credbull/token/CBL.sol";

import { DeployedContracts } from "@script/DeployedContracts.s.sol";
import { TokenConfigured } from "./Configured.s.sol";

abstract contract DeployCBLToken is TokenConfigured {
    bool private isTestMode;

    function deployTo(string memory network) internal returns (CBL) {
        return deployCBLToken(network);
    }

    function deployCBLToken(string memory network) internal returns (CBL cbl) {
        DeployedContracts deployChecker = new DeployedContracts();
        address owner = tokenOwner(network);
        address minter = tokenMinter(network);
        uint256 maxSupply = tokenMaxSupply(network);

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CBL")) {
            cbl = new CBL(owner, minter, maxSupply);
        }

        vm.stopBroadcast();

        return cbl;
    }
}

contract Arbitrum is DeployCBLToken {
    function run() external {
        deployTo("Arbitrum");
    }
}

contract Test is DeployCBLToken {
    function runTest() external returns (CBL) {
        return deployTo("Test");
    }
}
