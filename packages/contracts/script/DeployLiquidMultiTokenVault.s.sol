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

import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployLiquidMultiTokenVault is TomlConfig {
    using stdToml for string;

    string private _tomlConfig;
    LiquidContinuousMultiTokenVault.VaultAuth internal _vaultAuth;

    uint256 public constant NOTICE_PERIOD = 1;
    string public constant CONTRACT_TOML_KEY = ".evm.contracts.liquid_continuous_multi_token_vault";

    constructor() {
        _tomlConfig = loadTomlConfiguration();

        _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
            owner: _tomlConfig.readAddress(".evm.address.owner"),
            operator: _tomlConfig.readAddress(".evm.address.operator"),
            upgrader: _tomlConfig.readAddress(".evm.address.upgrader"),
            assetManager: _tomlConfig.readAddress(".evm.address.asset_manager")
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

        _deployTimelockAsyncUnlock();

        return LiquidContinuousMultiTokenVault(address(liquidVaultProxy));
    }

    function _createVaultParams(
        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth,
        IERC20Metadata asset,
        IYieldStrategy yieldStrategy,
        IRedeemOptimizer redeemOptimizer
    ) public view virtual returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_) {
        uint256 fullRateBasisPoints = _tomlConfig.readUint(string.concat(CONTRACT_TOML_KEY, ".full_rate_bps"));
        uint256 reducedRateBasisPoints = _tomlConfig.readUint(string.concat(CONTRACT_TOML_KEY, ".reduced_rate_bps"));
        uint256 startTimestamp = _startTimestamp();
        uint256 redeemNoticePeriod =
            _readUintWithDefault(_tomlConfig, string.concat(CONTRACT_TOML_KEY, ".redeem_notice_period"), 1);

        uint256 decimals = asset.decimals();
        uint256 scale = 10 ** decimals;

        TripleRateContext.ContextParams memory contextParams = TripleRateContext.ContextParams({
            fullRateScaled: fullRateBasisPoints * scale / 100,
            initialReducedRate: ITripleRateContext.PeriodRate({
                interestRate: reducedRateBasisPoints * scale / 100,
                effectiveFromPeriod: 0
            }),
            frequency: 360,
            tenor: 30,
            decimals: decimals
        });

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = LiquidContinuousMultiTokenVault.VaultParams({
            vaultAuth: vaultAuth,
            asset: asset,
            yieldStrategy: yieldStrategy,
            redeemOptimizer: redeemOptimizer,
            vaultStartTimestamp: startTimestamp,
            redeemNoticePeriod: redeemNoticePeriod,
            contextParams: contextParams
        });

        return vaultParams;
    }

    function _startTimestamp() internal view virtual returns (uint256 startTimestamp_) {
        return _readUintWithDefault(
            _tomlConfig, string.concat(CONTRACT_TOML_KEY, ".vault_start_timestamp"), block.timestamp
        );
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

    function _deployTimelockAsyncUnlock() internal {
        bool shouldDeployMocks = _readBoolWithDefault(_tomlConfig, ".evm.deploy_mocks", false);

        if (shouldDeployMocks) {
            vm.startBroadcast();
            IERC5679Ext1155 deposits = new ERC1155MintableBurnable();

            SimpleTimelockAsyncUnlock asyncUnlockImpl = new SimpleTimelockAsyncUnlock();

            ERC1967Proxy asyncUnlockProxy = new ERC1967Proxy(
                address(asyncUnlockImpl),
                abi.encodeWithSelector(asyncUnlockImpl.initialize.selector, NOTICE_PERIOD, deposits)
            );

            console2.log(
                string.concat(
                    "!!!!! Deploying SimpleTimelockAsyncUnlock Proxy [",
                    vm.toString(address(asyncUnlockProxy)),
                    "] !!!!!"
                )
            );
            vm.stopBroadcast();
        }
    }
}
