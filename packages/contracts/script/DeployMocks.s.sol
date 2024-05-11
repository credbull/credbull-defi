//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";

import { console2 } from "forge-std/console2.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";
import { CredbullBaseVaultMock } from "../test/mocks/vaults/CredbullBaseVaultMock.m.sol";

contract DeployMocks is Script {
    bool public isTestMode;
    address private custodian;
    uint128 public constant MAX_UINT128_SIZE = type(uint128).max;

    uint128 public totalSupply = MAX_UINT128_SIZE;

    CredbullBaseVaultMock internal credbullBaseVaultMock;

    constructor(bool _isTestMode, address _custodian) {
        isTestMode = _isTestMode;
        custodian = _custodian;
    }

    function run() public returns (MockToken, MockStablecoin) {
        DeployedContracts deployChecker = new DeployedContracts();

        MockToken mockToken;
        MockStablecoin mockStablecoin;

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("MockToken")) {
            mockToken = new MockToken(totalSupply);
            console2.log("!!!!! Deploying MockToken !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("MockStablecoin")) {
            mockStablecoin = new MockStablecoin(totalSupply);
            console2.log("!!!!! Deploying MockStablecoin !!!!!");
        } else {
            address mockTokenAddress = deployChecker.getContractAddress("MockStablecoin");
            mockToken = MockToken(mockTokenAddress);
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullBaseVaultMock")) {
            // HACK TODO: this only works if the MockToken was re-deployed.  Proper solution would be to fetch the MockToken address from supabase.
            credbullBaseVaultMock = new CredbullBaseVaultMock(mockToken, "Mock Vault", "mVault", custodian);
            console2.log("!!!!! Deploying CredbullBaseVaultMock !!!!!");
        }

        vm.stopBroadcast();

        return (mockToken, mockStablecoin);
    }
}
