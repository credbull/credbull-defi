//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";

import { DeployCredbullToken } from "./DeployCredbullToken.s.sol";
import { CredbullToken } from "../contracts/CredbullToken.sol";

import { INetworkConfig, NetworkConfig } from "./utils/NetworkConfig.s.sol";
import { LocalNetworkConfig } from "./utils/LocalNetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { DeployCredbullVault } from "./DeployCredbullVault.s.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";

import { ChainUtil } from "./utils/ChainUtil.sol";

import { ScaffoldETHDeploy } from "./DeployHelpers.s.sol";

contract DeployScript is ScaffoldETHDeploy {
    ChainUtil private chaintUtil = new ChainUtil();

    error InvalidPrivateKey(string);

    function run() external returns (CredbullVault) {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        address deployerAddress = vm.addr(deployerPrivateKey);

        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        // open the wallet first in order to use the address (not the private key) in subsequent calls.
        unlockWallet(deployerPrivateKey);

        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();
        CredbullToken credbullToken = deployCredbullToken.run(deployerAddress);

        INetworkConfig networkConfig = createNetworkConfig(deployerAddress, credbullToken);

        DeployCredbullVault deployCredbullVault = new DeployCredbullVault(networkConfig);
        CredbullVault credbullVault = deployCredbullVault.run(deployerAddress);

        return credbullVault;
    }

    // unlock wallet by starting a transaction.
    function unlockWallet(uint256 deployerPrivateKey) internal {
        vm.startBroadcast(deployerPrivateKey);
        // we don't have to do anything, just start and stop the broadcast with the private key.
        vm.stopBroadcast();
    }

    function createNetworkConfig(address deployerAddress, IERC20 defaultVaultToken) internal returns (INetworkConfig) {
        // ---------- create for local chain ----------
        if (chaintUtil.isLocalChain()) {
            return new LocalNetworkConfig(deployerAddress, true);
        }

        // ---------- create for remote chain ----------
        address usdcAddress = vm.envAddress("USDC_CONTRACT_ADDRESS");

        address vaultAssetAddress = vm.envOr("CREDBULL_VAULT_ASSET_ADDRESS", address(defaultVaultToken));
        if (vaultAssetAddress == address(defaultVaultToken)) {
            console.log("CREDBULL_VAULT_ASSET_ADDRESS not found in Environment.  Using default of: ", vaultAssetAddress);
        }

        INetworkConfig networkConfig = new NetworkConfig(IERC20(usdcAddress), IERC20(vaultAssetAddress));

        return networkConfig;
    }

    function test() public { }
}
