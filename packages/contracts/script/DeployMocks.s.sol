//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployMocks is Script {
    bool public isTestMode;
    address private custodian;
    uint128 public constant MAX_UINT128_SIZE = type(uint128).max;

    uint128 public totalSupply = MAX_UINT128_SIZE;

    SimpleVault internal testVault;

    constructor(bool _isTestMode, address _custodian) {
        isTestMode = _isTestMode;
        custodian = _custodian;
    }

    function run() public returns (SimpleToken, SimpleUSDC) {
        DeployedContracts deployChecker = new DeployedContracts();

        address owner = msg.sender;

        SimpleToken testToken;
        SimpleUSDC testStablecoin;

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("SimpleToken")) {
            testToken = new SimpleToken(owner, totalSupply);
            console2.log("!!!!! Deploying SimpleToken !!!!!");
        } else {
            testToken = SimpleToken(deployChecker.getContractAddress("SimpleToken"));
        }

        if (isTestMode || deployChecker.isDeployRequired("SimpleUSDC")) {
            testStablecoin = new SimpleUSDC(owner, totalSupply);
            console2.log("!!!!! Deploying SimpleToken !!!!!");
        } else {
            testStablecoin = SimpleUSDC(deployChecker.getContractAddress("SimpleUSDC"));
        }

        if (isTestMode || deployChecker.isDeployRequired("SimpleVault")) {
            Vault.VaultParams memory params = Vault.VaultParams({
                asset: testStablecoin,
                shareName: "Simple Vault",
                shareSymbol: "smpVLT",
                custodian: custodian
            });
            testVault = new SimpleVault(params);
            console2.log("!!!!! Deploying Simple Vault !!!!!");
        }

        vm.stopBroadcast();

        return (testToken, testStablecoin);
    }
}
