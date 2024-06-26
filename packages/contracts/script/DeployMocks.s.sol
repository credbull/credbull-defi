//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { Vault } from "@src/vault/Vault.sol";

import { MockStablecoin } from "@test/test/mock/MockStablecoin.t.sol";
import { MockToken } from "@test/test/mock/MockToken.t.sol";
import { MockVault } from "@test/test/mock/vault/MockVault.t.sol";

import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployMocks is Script {
    bool public isTestMode;
    address private custodian;
    uint128 public constant MAX_UINT128_SIZE = type(uint128).max;

    uint128 public totalSupply = MAX_UINT128_SIZE;

    MockVault internal mockVault;

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
        } else {
            mockStablecoin = MockStablecoin(deployChecker.getContractAddress("MockStablecoin"));
        }

        if (isTestMode || deployChecker.isDeployRequired("MockStablecoin")) {
            mockStablecoin = new MockStablecoin(totalSupply);
            console2.log("!!!!! Deploying MockStablecoin !!!!!");
        } else {
            mockToken = MockToken(deployChecker.getContractAddress("MockStablecoin"));
        }

        if (isTestMode || deployChecker.isDeployRequired("MockVault")) {
            Vault.VaultParameters memory params = Vault.VaultParameters({
                asset: mockStablecoin,
                shareName: "Mock Vault",
                shareSymbol: "mVault",
                custodian: custodian
            });
            mockVault = new MockVault(params);
            console2.log("!!!!! Deploying CredbullBaseVaultMock !!!!!");
        }

        vm.stopBroadcast();

        return (mockToken, mockStablecoin);
    }
}
