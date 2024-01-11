// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";
import { INetworkConfig } from "./utils/NetworkConfig.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ScaffoldETHDeploy } from "./DeployHelpers.s.sol";

import { console } from "forge-std/console.sol";

contract DeployCredbullVault is ScaffoldETHDeploy {
    string private constant VAULT_SHARE_NAME = "VAULT Token";
    string private constant VAULT_SHARE_SYMBOL = "VAULT";

    INetworkConfig public networkConfig;

    constructor(INetworkConfig _networkConfig) {
        networkConfig = _networkConfig;
    }

    function run() public returns (CredbullVault) {
        return run(msg.sender);
    }

    function run(address contractOwnerAddress) public returns (CredbullVault) {
        vm.startBroadcast(contractOwnerAddress);

        IERC20 credbullVaultAsset = getCredbullVaultAsset();

        CredbullVault credbullVault = new CredbullVault(
            contractOwnerAddress,
            credbullVaultAsset,
            VAULT_SHARE_NAME,
            VAULT_SHARE_SYMBOL,
            0xA98308F10b7850bDBEBcE707E70dD3A3aE832cc6
        );

        console.logString(string.concat("CredbullVault deployed at: ", vm.toString(address(credbullVault))));

        vm.stopBroadcast();

        exportDeployments(); // generates file with Abi's.  call this last.

        return credbullVault;
    }

    function getVaultShareSymbol() public pure returns (string memory) {
        return VAULT_SHARE_SYMBOL;
    }

    function getCredbullVaultAsset() public view returns (IERC20) {
        return networkConfig.getCredbullVaultAsset();
    }
}
