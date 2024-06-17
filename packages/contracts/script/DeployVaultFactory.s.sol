//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultFactory } from "../src/factories/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "../src/factories/CredbullUpsideVaultFactory.sol";
import { CredbullKYCProvider } from "../src/CredbullKYCProvider.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

import { ICredbull } from "../src/interface/ICredbull.sol";
import { CredbullFixedYieldVault } from "../src/CredbullFixedYieldVault.sol";
import { InCredbullVaultParams } from "./InCredbullVaultParams.s.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployVaultFactory is Script {
    bool private isTestMode;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            CredbullKYCProvider kycProvider,
            HelperConfig helperConfig
        )
    {
        isTestMode = true;
        return run();
    }

    function run()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            CredbullKYCProvider kycProvider,
            HelperConfig helperConfig
        )
    {
        helperConfig = new HelperConfig(isTestMode);
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner = config.factoryParams.owner;
        address operator = config.factoryParams.operator;

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CredbullFixedYieldVaultFactory")) {
            factory = new CredbullFixedYieldVaultFactory(owner, operator);
            console2.log("!!!!! Deploying CredbullFixedYieldVaultFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullUpsideVaultFactory")) {
            upsideFactory = new CredbullUpsideVaultFactory(owner, operator);
            console2.log("!!!!! Deploying CredbullVaultWithUpsideFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullKYCProvider")) {
            kycProvider = new CredbullKYCProvider(operator);
            console2.log("!!!!! Deploying CredbullKYCProvider !!!!!");
        }

        vm.stopBroadcast();

        return (factory, upsideFactory, kycProvider, helperConfig);
    }

    function deployVault() public returns (HelperConfig, CredbullFixedYieldVault) {
        HelperConfig helperConfig = new HelperConfig(isTestMode);
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner = config.factoryParams.owner;
        address operator = config.factoryParams.operator;
        address custodian = config.factoryParams.custodian;
        uint256 opensAt = (block.timestamp + 1 weeks);

        // create outside of startBroadcast transaction.  we don't want to deploy this.
        InCredbullVaultParams params = new InCredbullVaultParams();

        vm.startBroadcast();

        ICredbull.VaultParams memory usdc10APYParams =
            params.create10APYParams("iC10D", config.usdcToken, owner, operator, custodian, opensAt);
        usdc10APYParams.kycProvider = owner;

        CredbullFixedYieldVault usdc10APYVault = new CredbullFixedYieldVault(usdc10APYParams);
        console2.log("CredbullFixedYieldVault", " deployed at: ", address(usdc10APYVault));
        console2.logBytes(abi.encode(usdc10APYParams));

        vm.stopBroadcast();

        return (helperConfig, usdc10APYVault);
    }
}
