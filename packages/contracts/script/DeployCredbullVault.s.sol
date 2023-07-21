// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CredbullVault} from "../src/CredbullVault.sol";
import {DeployHelper, INetworkConfig} from "./DeployHelper.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DeployCredbullVault is Script {
    string public constant VAULT_SHARE_NAME = "VAULT Token";
    string public constant VAULT_SHARE_SYMBOL = "VAULT";

    function getCredbullVaultAsset() public returns (IERC20) {
        DeployHelper deployHelper = new DeployHelper();
        
        INetworkConfig networkConfig = deployHelper.activeNetworkConfig();
                
        return networkConfig.getCredbullVaultAsset();
    }

    function run() public returns (CredbullVault) {
        IERC20 credbullVaultAsset = getCredbullVaultAsset();

        vm.startBroadcast();
        CredbullVault credbullVault = new CredbullVault(
            credbullVaultAsset,
            VAULT_SHARE_NAME,
            VAULT_SHARE_SYMBOL
        );
        vm.stopBroadcast();

        return credbullVault;
    }
}
