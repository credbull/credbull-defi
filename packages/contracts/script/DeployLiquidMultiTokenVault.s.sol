//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";

import { TomlConfig } from "@script/TomlConfig.s.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployLiquidMultiTokenVault is TomlConfig {
    using stdToml for string;

    string private _tomlConfig;
    LiquidContinuousMultiTokenVault.VaultAuth public _vaultAuth;

    constructor() {
        _tomlConfig = loadTomlConfiguration();

        _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
            owner: _tomlConfig.readAddress(".evm.address.owner"),
            operator: _tomlConfig.readAddress(".evm.address.operator"),
            upgrader: _tomlConfig.readAddress(".evm.address.upgrader")
        });
    }

    function run() public returns (LiquidContinuousMultiTokenVault vault) {
        return run(_vaultAuth);
    }

    function run(LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth)
        public
        virtual
        returns (LiquidContinuousMultiTokenVault vault)
    {
        IERC20Metadata usdc = _usdcOrDeployMock(vaultAuth.owner);

        vm.startBroadcast();

        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        console2.log(string.concat("!!!!! Deploying IYieldStrategy [", vm.toString(address(yieldStrategy)), "] !!!!!"));

        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, 0);
        console2.log(
            string.concat("!!!!! Deploying IRedeemOptimizer [", vm.toString(address(redeemOptimizer)), "] !!!!!")
        );

        vm.stopBroadcast();

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            _createVaultParams(vaultAuth, usdc, yieldStrategy, redeemOptimizer);

        vm.startBroadcast();

        LiquidContinuousMultiTokenVault liquidVaultImpl = new LiquidContinuousMultiTokenVault();
        console2.log(
            string.concat(
                "!!!!! Deploying LiquidContinuousMultiTokenVault Implementation [",
                vm.toString(address(liquidVaultImpl)),
                "] !!!!!"
            )
        );

        ERC1967Proxy liquidVaultProxy = new ERC1967Proxy(
            address(liquidVaultImpl), abi.encodeWithSelector(liquidVaultImpl.initialize.selector, vaultParams)
        );
        console2.log(
            string.concat(
                "!!!!! Deploying LiquidContinuousMultiTokenVault Proxy [",
                vm.toString(address(liquidVaultProxy)),
                "] !!!!!"
            )
        );

        vm.stopBroadcast();

        return LiquidContinuousMultiTokenVault(address(liquidVaultProxy));
    }

    function _createVaultParams(
        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth,
        IERC20Metadata asset,
        IYieldStrategy yieldStrategy,
        IRedeemOptimizer redeemOptimizer
    ) public view returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_) {
        string memory contractKey = ".evm.contracts.liquid_continuous_multi_token_vault";
        uint256 fullRateBasisPoints = _tomlConfig.readUint(string.concat(contractKey, ".full_rate_bps"));
        uint256 reducedRateBasisPoints = _tomlConfig.readUint(string.concat(contractKey, ".reduced_rate_bps"));
        uint256 startTimestamp =
            _readUintWithDefault(_tomlConfig, string.concat(contractKey, ".vault_start_timestamp"), block.timestamp);

        uint256 scale = 10 ** asset.decimals();

        TripleRateContext.ContextParams memory contextParams = TripleRateContext.ContextParams({
            fullRateScaled: fullRateBasisPoints * scale / 100,
            initialReducedRate: ITripleRateContext.PeriodRate({
                interestRate: reducedRateBasisPoints * scale / 100,
                effectiveFromPeriod: 0
            }),
            frequency: 360,
            tenor: 30,
            decimals: asset.decimals()
        });

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = LiquidContinuousMultiTokenVault.VaultParams({
            vaultAuth: vaultAuth,
            asset: asset,
            yieldStrategy: yieldStrategy,
            redeemOptimizer: redeemOptimizer,
            vaultStartTimestamp: startTimestamp,
            redeemNoticePeriod: 1,
            contextParams: contextParams
        });

        return vaultParams;
    }

    function _usdcOrDeployMock(address contractOwner) internal returns (IERC20Metadata asset) {
        bool shouldDeployMocks = _readBoolWithDefault(_tomlConfig, ".evm.deploy_mocks", false);

        if (shouldDeployMocks) {
            vm.startBroadcast();

            SimpleUSDC simpleUSDC = new SimpleUSDC(contractOwner, type(uint128).max);
            console2.log(string.concat("!!!!! Deploying SimpleUSDC [", vm.toString(address(simpleUSDC)), "] !!!!!"));

            vm.stopBroadcast();

            return simpleUSDC;
        } else {
            return IERC20Metadata(_tomlConfig.readAddress(".evm.address.usdc_token"));
        }
    }
}
