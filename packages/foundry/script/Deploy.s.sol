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
import { EnvUtil } from "./utils/EnvUtil.sol";

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
        deployCredbullToken.run(deployerAddress);

        INetworkConfig networkConfig = createNetworkConfig(deployerAddress);

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

    function createNetworkConfig(address deployerAddress) internal returns (INetworkConfig) {
        // ---------- create for local chain ----------
        if (chaintUtil.isLocalChain()) {
            return new LocalNetworkConfig(deployerAddress);
        }

        // ---------- create for remote chain ----------
        // grab contract addresses from the environment
        address usdcAddress = new EnvUtil().getAddressFromEnvironment("USDC_CONTRACT_ADDRESS");

        IERC20 usdc = IERC20(usdcAddress);

        INetworkConfig networkConfig = new NetworkConfig(usdc, usdc);

        return networkConfig;
    }

    function test() public { }
}
