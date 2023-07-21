// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CredbullVault} from "../src/CredbullVault.sol";
import {DeployHelper, INetworkConfig} from "./DeployHelper.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";

contract DeployCredbullVault is Script {
    string private constant VAULT_SHARE_NAME = "VAULT Token";
    string private constant VAULT_SHARE_SYMBOL = "VAULT";

    IERC20 public credbullVaultAsset;

    function run() public returns (CredbullVault) {
        DeployHelper deployHelper = new DeployHelper();
        INetworkConfig networkConfig = deployHelper.activeNetworkConfig();

        credbullVaultAsset = networkConfig.getCredbullVaultAsset();

        vm.startBroadcast();
        CredbullVault credbullVault = new CredbullVault(
            credbullVaultAsset,
            VAULT_SHARE_NAME,
            VAULT_SHARE_SYMBOL
        );
        vm.stopBroadcast();

        return credbullVault;
    }

    function getVaultShareSymbol() public pure returns (string memory) {
        return VAULT_SHARE_SYMBOL;
    }

    function getCredbullVaultAsset() public view returns (IERC20) {
        return credbullVaultAsset;
    }
}
