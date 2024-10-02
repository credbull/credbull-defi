//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";

import { TomlConfig } from "./TomlConfig.s.sol";
import { stdToml } from "forge-std/StdToml.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployLiquidMultiTokenVault is TomlConfig {
    using stdToml for string;

    string private tomlConfig;

    address private owner;
    address private operator;

    constructor() {
        tomlConfig = loadTomlConfiguration();

        owner = tomlConfig.readAddress(".evm.address.owner");
        operator = tomlConfig.readAddress(".evm.address.operator");
    }

    function run() public returns (LiquidContinuousMultiTokenVault vault) {
        return run(owner);
    }

    function run(address contractOwner) public returns (LiquidContinuousMultiTokenVault vault) {
        IERC20Metadata usdc = _usdcOrDeployMock(contractOwner);

        IYieldStrategy yieldStrategy = _deployYieldStrategy(contractOwner);

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            _createVaultParams(contractOwner, usdc, yieldStrategy);

        vm.startBroadcast(contractOwner);

        LiquidContinuousMultiTokenVault liquidVault = new LiquidContinuousMultiTokenVault(vaultParams);
        console2.log(
            string.concat(
                "!!!!! Deploying LiquidContinuousMultiTokenVault [", vm.toString(address(liquidVault)), "] !!!!!"
            )
        );

        vm.stopBroadcast();

        return liquidVault;
    }

    function _createVaultParams(address contractOwner, IERC20Metadata asset, IYieldStrategy yieldStrategy)
        internal
        view
        returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_)
    {
        string memory contractKey = ".evm.contracts.liquid_continuous_multi_token_vault";
        uint256 fullRateBasisPoints = tomlConfig.readUint(string.concat(contractKey, ".full_rate_bps"));
        uint256 reducedRateBasisPoints = tomlConfig.readUint(string.concat(contractKey, ".reduced_rate_bps"));
        uint256 startTimestamp =
            _readUintWithDefault(tomlConfig, string.concat(contractKey, ".vault_start_timestamp"), block.timestamp);

        uint256 scale = 10 ** asset.decimals();

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = LiquidContinuousMultiTokenVault.VaultParams({
            contractOwner: contractOwner,
            contractOperator: operator,
            asset: asset,
            yieldStrategy: yieldStrategy,
            vaultStartTimestamp: startTimestamp,
            redeemNoticePeriod: 1,
            fullRateScaled: fullRateBasisPoints * scale / 100,
            reducedRateScaled: reducedRateBasisPoints * scale / 100,
            frequency: 360,
            tenor: 30
        });

        return vaultParams;
    }

    function _deployYieldStrategy(address contractOwner) internal returns (IYieldStrategy) {
        vm.startBroadcast(contractOwner);

        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        console2.log(
            string.concat("!!!!! Deploying TripleRateYieldStrategy [", vm.toString(address(yieldStrategy)), "] !!!!!")
        );

        vm.stopBroadcast();

        return yieldStrategy;
    }

    function _usdcOrDeployMock(address contractOwner) internal returns (IERC20Metadata asset) {
        bool shouldDeployMocks = _readBoolWithDefault(tomlConfig, ".evm.deploy_mocks", false);

        if (shouldDeployMocks) {
            vm.startBroadcast(contractOwner);

            SimpleUSDC simpleUSDC = new SimpleUSDC(type(uint128).max);
            console2.log(string.concat("!!!!! Deploying SimpleUSDC [", vm.toString(address(simpleUSDC)), "] !!!!!"));

            vm.stopBroadcast();

            return simpleUSDC;
        } else {
            return IERC20Metadata(tomlConfig.readAddress(".evm.address.usdc_token"));
        }
    }
}
