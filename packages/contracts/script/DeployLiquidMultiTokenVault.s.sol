//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";

import { TomlConfig } from "./TomlConfig.s.sol";
import { stdToml } from "forge-std/StdToml.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployLiquidMultiTokenVault is TomlConfig {
    using stdToml for string;

    string private tomlConfig;

    constructor() {
        tomlConfig = loadTomlConfiguration();
    }

    function run() public returns (LiquidContinuousMultiTokenVault vault) {
        address owner = tomlConfig.readAddress(".evm.address.owner");
        // address operator = tomlConfig.readAddress(".evm.address.operator"); // TODO - add in operator as param

        vm.startBroadcast();

        SimpleUSDC simpleUSDC = new SimpleUSDC(type(uint128).max);
        console2.log("!!!!! Deploying SimpleToken !!!!!");

        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        console2.log("!!!!! Deploying TripleRateYieldStrategy !!!!!");

        uint256 scale = 10 ** simpleUSDC.decimals();

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = LiquidContinuousMultiTokenVault.VaultParams({
            contractOwner: owner,
            asset: simpleUSDC,
            yieldStrategy: yieldStrategy,
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            fullRateScaled: 10 * scale,
            reducedRateScaled: 55 * scale / 100,
            frequency: 360,
            tenor: 30
        });

        LiquidContinuousMultiTokenVault liquidVault = new LiquidContinuousMultiTokenVault(vaultParams);
        console2.log("!!!!! Deploying LiquidContinuousMultiTokenVault !!!!!");

        vm.stopBroadcast();

        return liquidVault;
    }
}
