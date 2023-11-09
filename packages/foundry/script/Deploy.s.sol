//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";

import {DeployCredbullToken} from "./DeployCredbullToken.s.sol";
import {CredbullToken} from "../contracts/CredbullToken.sol";

import {NetworkConfigs, INetworkConfig} from "./utils/NetworkConfig.s.sol";
import {LocalNetworkConfigs} from "./utils/LocalNetworkConfig.s.sol";

import {DeployCredbullVault} from "./DeployCredbullVault.s.sol";
import {CredbullVault} from "../contracts/CredbullVault.sol";

import {ChainUtil} from "./utils/ChainUtil.sol";

import {ScaffoldETHDeploy} from "./DeployHelpers.s.sol";
import "./utils/LocalNetworkConfig.s.sol";

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

        DeployCredbullToken deployCredbullToken = new DeployCredbullToken();
        deployCredbullToken.run(deployerAddress);


        NetworkConfigs networkConfigs = getNetworkConfigs(deployerAddress);

        DeployCredbullVault deployCredbullVault = new DeployCredbullVault(networkConfigs.getNetworkConfig());
        CredbullVault credbullVault = deployCredbullVault.run(deployerAddress);

        deployYourContract(deployerPrivateKey);

        return credbullVault;
    }

    function getNetworkConfigs(address deployerAddress) internal returns (NetworkConfigs) {
        return chaintUtil.isLocalChain() ? new LocalNetworkConfigs(deployerAddress) : new NetworkConfigs();
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
