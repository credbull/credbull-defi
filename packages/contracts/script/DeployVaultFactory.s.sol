//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { ITripleRateContext } from "@credbull/yield/context/ITripleRateContext.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployVaultFactory is Script {
    bool private isTestMode;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullUpsideVaultFactory upsideFactory,
            CredbullWhiteListProvider whiteListProvider,
            HelperConfig helperConfig,
            LiquidContinuousMultiTokenVault vault
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
            CredbullWhiteListProvider whiteListProvider,
            HelperConfig helperConfig,
            LiquidContinuousMultiTokenVault vault
        )
    {
        helperConfig = new HelperConfig(isTestMode);
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        address owner = config.factoryParams.owner;
        address operator = config.factoryParams.operator;
        address[] memory custodians = new address[](1);
        custodians[0] = config.factoryParams.custodian;

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();

        if (isTestMode || deployChecker.isDeployRequired("CredbullFixedYieldVaultFactory")) {
            factory = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
            console2.log("!!!!! Deploying CredbullFixedYieldVaultFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullUpsideVaultFactory")) {
            upsideFactory = new CredbullUpsideVaultFactory(owner, operator, custodians);
            console2.log("!!!!! Deploying CredbullVaultWithUpsideFactory !!!!!");
        }

        if (isTestMode || deployChecker.isDeployRequired("CredbullWhiteListProvider")) {
            whiteListProvider = new CredbullWhiteListProvider(operator);
            console2.log("!!!!! Deploying CredbullWhiteListProvider !!!!!");
        }

        LiquidContinuousMultiTokenVault _vault = _deployVaultContracts(config, owner, operator);

        vm.stopBroadcast();

        return (factory, upsideFactory, whiteListProvider, helperConfig, _vault);
    }

    function _deployVaultContracts(NetworkConfig memory config, address owner, address operator)
        internal
        returns (LiquidContinuousMultiTokenVault)
    {
        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        console2.log(string.concat("!!!!! Deploying IYieldStrategy [", vm.toString(address(yieldStrategy)), "] !!!!!"));

        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, 0);
        console2.log(
            string.concat("!!!!! Deploying IRedeemOptimizer [", vm.toString(address(redeemOptimizer)), "] !!!!!")
        );

        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth =
            LiquidContinuousMultiTokenVault.VaultAuth({ owner: owner, operator: operator, upgrader: owner });

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            _createVaultParams(vaultAuth, IERC20Metadata(address(config.usdcToken)), yieldStrategy, redeemOptimizer);

        LiquidContinuousMultiTokenVault liquidVaultImpl = new LiquidContinuousMultiTokenVault();
        console2.log(
            string.concat(
                "!!!!! Deploying LiquidContinuousMultiTokenVault Implementation [",
                vm.toString(address(liquidVaultImpl)),
                "] !!!!!"
            )
        );

        liquidVaultImpl.initialize(vaultParams);

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

        return LiquidContinuousMultiTokenVault(address(liquidVaultProxy));
    }

    function _createVaultParams(
        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth,
        IERC20Metadata asset,
        IYieldStrategy yieldStrategy,
        IRedeemOptimizer redeemOptimizer
    ) public view returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_) {
        uint256 fullRateBasisPoints = 1000;
        uint256 reducedRateBasisPoints = 550;
        uint256 startTimestamp = block.timestamp;

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
}
