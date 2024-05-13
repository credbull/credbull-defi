//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { NetworkConfig, FactoryParams } from "../script/HelperConfig.s.sol";
import { HelperVaultTest } from "../test/base/HelperVaultTest.t.sol";

import { ICredbull } from "../src/interface/ICredbull.sol";

import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { CredbullBaseVaultMock } from "../test/mocks/vaults/CredbullBaseVaultMock.m.sol";

import { CredbullFixedYieldVaultFactory } from "../src/factories/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "../src/CredbullFixedYieldVault.sol";
import { HelperVaultTest } from "../test/base/HelperVaultTest.t.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";

contract DebugDeploy is Script {
    address private mockStablecoinAddr = address(10); // from supabase
    address payable private mockBaseVaultAddr = payable(address(11)); // from supabase
    address payable private fixedYieldVaultFactoryAddr = payable(address(12)); // from supabase

    uint256 ownerPrivateKey = 0; // ..ff80 is anvil-0
    uint256 operatorPrivateKey = 1; // ..690d is anvil-1

    function run()
        public
        returns (MockStablecoin, CredbullBaseVaultMock, CredbullFixedYieldVaultFactory, CredbullFixedYieldVault)
    {
        //DeployedContracts deployChecker = new DeployedContracts();

        // address mockStablecoinAddr = deployChecker.getContractAddress("MockStablecoin"); // output file missing ?!?
        // address mockBaseVaultAddr = deployChecker.getContractAddress("CredbullBaseVaultMock"); // output file missing ?!?
        // address fixedYieldVaultFactoryAddr = deployChecker.getContractAddress("CredbullFixedYieldVaultFactory"); // output file missing ?!?

        MockStablecoin mockStablecoin = MockStablecoin(mockStablecoinAddr);
        CredbullBaseVaultMock mockBaseVault = CredbullBaseVaultMock(mockBaseVaultAddr);
        CredbullFixedYieldVaultFactory fixedYieldVaultFactory =
            CredbullFixedYieldVaultFactory(fixedYieldVaultFactoryAddr);

        FactoryParams memory factoryParams = FactoryParams({
            owner: vm.addr(ownerPrivateKey),
            operator: vm.addr(operatorPrivateKey),
            collateralPercentage: 0
        });

        NetworkConfig memory anvilConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: mockStablecoin, cblToken: IERC20(address(0)) });

        HelperVaultTest helperVaultTest = new HelperVaultTest(anvilConfig);
        address custodian = address(1);

        // custodians need to be set by the VaultFactoryOwner
        vm.startBroadcast(ownerPrivateKey);
        fixedYieldVaultFactory.allowCustodian(custodian);
        vm.stopBroadcast();

        // custodians need to be set by the VaultFactoryOwner

        ICredbull.VaultParams memory vaultParams = helperVaultTest.createTestVaultParams(custodian);
        // need to set a kycProvider to avoid ZeroAddress error
        vaultParams.kycProvider = address(2);
        CredbullFixedYieldVault credbullFixedYieldVault = addVault(fixedYieldVaultFactory, vaultParams);

        return (mockStablecoin, mockBaseVault, fixedYieldVaultFactory, credbullFixedYieldVault);
    }

    function addVault(CredbullFixedYieldVaultFactory fixedYieldVaultFactory, ICredbull.VaultParams memory vaultParams)
        public
        returns (CredbullFixedYieldVault)
    {
        vm.startBroadcast(operatorPrivateKey); // vaults are deployed by operators

        address newVaultAddr = fixedYieldVaultFactory.createVault(vaultParams, "");
        vm.stopBroadcast();

        CredbullFixedYieldVault credbullFixedYieldVault = CredbullFixedYieldVault(payable(newVaultAddr));

        return credbullFixedYieldVault;
    }
}
