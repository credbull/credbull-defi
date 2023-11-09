//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";

import { DeployCredbullToken } from "./DeployCredbullToken.s.sol";
import { CredbullToken } from "../contracts/CredbullToken.sol";

import { NetworkConfigFactory, INetworkConfig } from "./utils/NetworkConfig.s.sol";
import { DeployCredbullVault } from "./DeployCredbullVault.s.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";

import { ScaffoldETHDeploy } from "./DeployHelpers.s.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external returns (CredbullVault) {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        address deployerAddress = vm.addr(deployerPrivateKey);

        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();
        deployCredbullToken.run(deployerAddress);

        CredbullVault credbullVault = doDeployCredbullVault(deployerAddress);

        deployYourContract(deployerPrivateKey);

        return credbullVault;
    }

    function doDeployCredbullVault(address deployerAddress) public returns (CredbullVault) {
        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(deployerAddress);
        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        DeployCredbullVault deployCredbullVault = new DeployCredbullVault(networkConfig);
        CredbullVault credbullVault = deployCredbullVault.run(deployerAddress);

        return credbullVault;
    }

        // using PK here.  Address results in error: "No associated wallet for addresses..."
    function deployYourContract(uint256 deployerPrivateKey) public returns (YourContract) {
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        YourContract yourContract = new YourContract(
            deployerAddress
        );
        console.logString(string.concat("YourContract deployed at: ", vm.toString(address(yourContract))));

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();

        return yourContract;
    }

    function test() public { }
}
