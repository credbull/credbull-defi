//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { HelperConfig, NetworkConfig } from "../../script/HelperConfig.s.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";

import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";
import { DeployedContracts } from "../../script/DeployedContracts.s.sol";

import { CredbullFixedYieldVaultFactory } from "../../src/factories/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";

import { ICredbull } from "../../src/interface/ICredbull.sol";

import { console2 } from "forge-std/console2.sol";

// TODO: Script was breaking build - moved to test package to see if it fixes it
contract DeployTestVault is Script {
    NetworkConfig private networkConfig;
    uint256 private vaultFactoryAdminKey;
    uint256 private vaultDeployerKey;

    constructor() {
        HelperConfig helperConfig = new HelperConfig(false);
        networkConfig = helperConfig.getNetworkConfig();
        vaultFactoryAdminKey = vm.envUint("DEFAULT_ANVIL_KEY"); // e.g. anvil account 1 ..690d
        vaultDeployerKey = vm.envUint("VAULT_DEPLOYER_KEY"); // e.g. anvil account 1 ..690d
    }

    function run() public returns (MockStablecoin, CredbullFixedYieldVaultFactory, CredbullFixedYieldVault) {
        DeployedContracts deployChecker = new DeployedContracts();

        MockStablecoin mockStablecoin = MockStablecoin(deployChecker.getContractAddress("MockStablecoin"));
        MockToken mockToken = MockToken(deployChecker.getContractAddress("MockToken"));

        CredbullFixedYieldVaultFactory fixedYieldVaultFactory =
            CredbullFixedYieldVaultFactory(deployChecker.getContractAddress("CredbullFixedYieldVaultFactory"));
        address kycProviderAddr = deployChecker.getContractAddress("CredbullKYCProvider");

        NetworkConfig memory configFromDatabase = NetworkConfig({
            factoryParams: networkConfig.factoryParams,
            usdcToken: mockStablecoin,
            cblToken: mockToken
        });

        HelperVaultTest helperVaultTest = new HelperVaultTest(configFromDatabase);
        address custodianAddr = vm.envAddress("ADDRESSES_CUSTODIAN");
        allowCustodian(custodianAddr, fixedYieldVaultFactory);

        ICredbull.VaultParams memory vaultParams = helperVaultTest.createTestVaultParams(custodianAddr, kycProviderAddr);

        CredbullFixedYieldVault credbullFixedYieldVault = addVault(fixedYieldVaultFactory, vaultParams);

        return (mockStablecoin, fixedYieldVaultFactory, credbullFixedYieldVault);
    }

    function allowCustodian(address _custodianAddr, CredbullFixedYieldVaultFactory _fixedYieldVaultFactory)
        internal
        pure
    {
        // TODO: this either hangs Waiting for receipts (when run by itself) OR
        // TODO: fails "EOA nonce changed unexpectedly while sending transactions. Expected 17 got 12 from provider." (when run with create-vault)
        //        vm.startBroadcast(vaultFactoryAdminKey); // custodians need to be set by the VaultFactoryOwner
        //        _fixedYieldVaultFactory.allowCustodian(_custodianAddr);
        //        vm.stopBroadcast();

        console2.log("Make sure custodian is allowed, e.g. by running the following command >>>");
        console2.log(
            "source .env && cast send --private-key $DEFAULT_ANVIL_KEY",
            address(_fixedYieldVaultFactory),
            "\"allowCustodian(address)\"",
            _custodianAddr
        );
    }

    function addVault(CredbullFixedYieldVaultFactory fixedYieldVaultFactory, ICredbull.VaultParams memory vaultParams)
        internal
        returns (CredbullFixedYieldVault)
    {
        vm.startBroadcast(vaultDeployerKey); // vaults are actually deployed by VaultFactoryOperators

        address newVaultAddr = fixedYieldVaultFactory.createVault(vaultParams, "{}");

        vm.stopBroadcast();

        CredbullFixedYieldVault credbullFixedYieldVault = CredbullFixedYieldVault(payable(newVaultAddr));

        return credbullFixedYieldVault;
    }
}
