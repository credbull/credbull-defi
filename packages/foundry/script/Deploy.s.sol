//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";

import {DeployCredbullToken} from "./DeployCredbullToken.s.sol";
import {CredbullToken} from "../contracts/CredbullToken.sol";

import {NetworkConfigFactory, INetworkConfig} from "./NetworkConfig.s.sol";
import {DeployCredbullVault} from "./DeployCredbullVault.s.sol";
import {CredbullVault} from "../contracts/CredbullVault.sol";

import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";

contract DeployScript is ScaffoldETHDeploy {
    error InvalidPrivateKey(string);

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        address deployerAddress = vm.addr(deployerPrivateKey);

        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();
        deployCredbullToken.run(deployerAddress);

        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory();
        INetworkConfig networkConfig = networkConfigFactory.createLocalNetwork(deployerAddress);
        DeployCredbullVault deployCredbullVault = new DeployCredbullVault(networkConfig);
        deployCredbullVault.run(deployerAddress);

        deployYourContract(deployerPrivateKey);
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

    function test() public {}
}
