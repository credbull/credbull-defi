//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";

import {DeployCredbullToken} from "./DeployCredbullToken.s.sol";
import {CredbullToken} from "../contracts/CredbullToken.sol";

import {DeployNetworkConfig, INetworkConfig} from "./NetworkConfig.s.sol";
import {DeployCredbullVault} from "./DeployCredbullVault.s.sol";
import {CredbullVault} from "../contracts/CredbullVault.sol";

import "./DeployHelpers.s.sol";

contract DeployScript is ScaffoldETHDeploy, DeployCredbullToken, DeployCredbullVault {
    error InvalidPrivateKey(string);

    constructor()
    DeployCredbullVault(new DeployNetworkConfig().getOrCreateLocalConfig())
    {}

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }
        vm.startBroadcast(deployerPrivateKey);

        YourContract yourContract = new YourContract(
            vm.addr(deployerPrivateKey)
        );
        console.logString(string.concat("YourContract deployed at: ", vm.toString(address(yourContract))));

        createCredbullToken();
        createCredbullVault();

        vm.stopBroadcast();

        /**
         * This function generates the file containing the contracts Abi definitions.
         * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
         * This function should be called last.
         */
        exportDeployments();
    }

    function test() public {}
}
