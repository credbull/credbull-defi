//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployLiquidMultiTokenVaultImplForUpgrade is Script {
    function run() public virtual returns (LiquidContinuousMultiTokenVault vaultImpl_) {
        vm.startBroadcast();

        LiquidContinuousMultiTokenVault liquidVaultImpl = new LiquidContinuousMultiTokenVault();
        console2.log(
            string.concat(
                "!!!!! Deploying LiquidContinuousMultiTokenVault Implementation [",
                vm.toString(address(liquidVaultImpl)),
                "] !!!!!"
            )
        );

        vm.stopBroadcast();

        return liquidVaultImpl;
    }
}
