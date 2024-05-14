//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { NetworkConfig } from "../script/HelperConfig.s.sol";
import { HelperVaultTest } from "../test/base/HelperVaultTest.t.sol";

import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

import { ICredbull } from "../src/interface/ICredbull.sol";
import { CredbullFixedYieldVaultFactory } from "../src/factories/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "../src/CredbullFixedYieldVault.sol";
import { HelperVaultTest } from "../test/base/HelperVaultTest.t.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";

// abstract so Script will not be Deployed in own file
abstract contract DebugDeploy is Script {
    NetworkConfig private networkConfig;
    uint256 private vaultDeployerKey;

    constructor(NetworkConfig memory _networkConfig, uint256 _vaultDeployerKey) {
        networkConfig = _networkConfig;
        vaultDeployerKey = _vaultDeployerKey;
    }

    function run() public returns (MockStablecoin, CredbullFixedYieldVaultFactory, CredbullFixedYieldVault) {
        DeployedContracts deployChecker = new DeployedContracts();

        MockStablecoin mockStablecoin = MockStablecoin(deployChecker.getContractAddress("MockStablecoin"));
        CredbullFixedYieldVaultFactory fixedYieldVaultFactory =
            CredbullFixedYieldVaultFactory(deployChecker.getContractAddress("CredbullFixedYieldVaultFactory"));
        address kycProviderAddr = deployChecker.getContractAddress("CredbullKYCProvider");

        NetworkConfig memory configFromDatabase = NetworkConfig({
            factoryParams: networkConfig.factoryParams,
            usdcToken: mockStablecoin,
            cblToken: IERC20(address(0))
        });

        HelperVaultTest helperVaultTest = new HelperVaultTest(configFromDatabase);
        address custodianAddr = vm.envAddress("ADDRESSES_CUSTODIAN");
        allowCustodian(custodianAddr, fixedYieldVaultFactory);

        ICredbull.VaultParams memory vaultParams = helperVaultTest.createTestVaultParams(custodianAddr, kycProviderAddr);

        CredbullFixedYieldVault credbullFixedYieldVault = addVault(fixedYieldVaultFactory, vaultParams);

        return (mockStablecoin, fixedYieldVaultFactory, credbullFixedYieldVault);
    }

    function allowCustodian(address _custodianAddr, CredbullFixedYieldVaultFactory _fixedYieldVaultFactory)
        public
        pure
    {
        // TODO: this just hangs - waiting for receipts.  Using cast as a work-around
        //        vm.startBroadcast();  // custodians need to be set by the VaultFactoryOwner
        //        _fixedYieldVaultFactory.allowCustodian(custodian);
        //        vm.stopBroadcast();

        console2.log("Make sure custodian is allowed, e.g. by running the following command");
        console2.log(
            "source .env && cast send --private-key $DEFAULT_ANVIL_KEY",
            address(_fixedYieldVaultFactory),
            "" "allowCustodian(address)" "",
            _custodianAddr
        );
    }

    function addVault(CredbullFixedYieldVaultFactory fixedYieldVaultFactory, ICredbull.VaultParams memory vaultParams)
        public
        returns (CredbullFixedYieldVault)
    {
        vm.startBroadcast(vaultDeployerKey); // vaults are actually deployed by VaultFactoryOperators

        address newVaultAddr = fixedYieldVaultFactory.createVault(vaultParams, "{}");

        vm.stopBroadcast();

        CredbullFixedYieldVault credbullFixedYieldVault = CredbullFixedYieldVault(payable(newVaultAddr));

        return credbullFixedYieldVault;
    }
}
