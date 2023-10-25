// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CredbullVault} from "../contracts/CredbullVault.sol";
import {DeployNetworkConfig, INetworkConfig} from "./NetworkConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {console} from "forge-std/console.sol";

contract DeployCredbullVault is Script {
    string private constant VAULT_SHARE_NAME = "VAULT Token";
    string private constant VAULT_SHARE_SYMBOL = "VAULT";

    INetworkConfig public networkConfig;

    constructor(INetworkConfig _networkConfig) {
        networkConfig = _networkConfig;
    }

    function createCredbullVault() public returns (CredbullVault) {
        IERC20 credbullVaultAsset = getCredbullVaultAsset();

        CredbullVault credbullVault = new CredbullVault(
            credbullVaultAsset,
            VAULT_SHARE_NAME,
            VAULT_SHARE_SYMBOL
        );

        console.logString(string.concat("CredbullVault deployed at: ", vm.toString(address(credbullVault))));

        return credbullVault;
    }

    function deployCredbullVault() public returns (CredbullVault) {
        vm.startBroadcast();

        CredbullVault credbullVault = createCredbullVault();

        vm.stopBroadcast();

        return credbullVault;
    }

    function getVaultShareSymbol() public pure returns (string memory) {
        return VAULT_SHARE_SYMBOL;
    }

    function getCredbullVaultAsset() public view returns (IERC20) {
        return networkConfig.getCredbullVaultAsset();
    }
}
