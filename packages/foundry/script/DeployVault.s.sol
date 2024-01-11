// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from 'forge-std/Script.sol';
import { CredbullVault } from '../contracts/CredbullVault.sol';
import { HelperConfig } from './HelperConfig.s.sol';
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployVault is Script {

    CredbullVault vault;

    function run() external returns(CredbullVault, HelperConfig) {

        HelperConfig helperConfig = new HelperConfig();
        (   
            address owner,
            address asset, 
            string memory shareName, 
            string memory shareSymbol,
            address custodian
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        vault = new CredbullVault(
            owner,
            IERC20(asset),
            shareName,
            shareSymbol,
            custodian
        );
        vm.stopBroadcast();
        return (vault, helperConfig);
    }
}