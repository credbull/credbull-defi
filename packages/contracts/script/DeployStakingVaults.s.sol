//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Vault } from "@credbull/vault/Vault.sol";
import { MaturityVault } from "@credbull/vault/MaturityVault.sol";
import { FixedYieldVault } from "@credbull/vault/FixedYieldVault.sol";
import { WindowPlugin } from "@credbull/plugin/WindowPlugin.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";
import { MaxCapPlugin } from "@credbull/plugin/MaxCapPlugin.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

contract DeployStakingVaults is Script {
    bool private isTestMode;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullFixedYieldVault[] memory stakingVaults,
            HelperConfig helperConfig
        )
    {
        isTestMode = true;
        return run();
    }

    function run()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullFixedYieldVault[] memory stakingVaults,
            HelperConfig helperConfig
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

        if (deployChecker.isFoundInContractDb("CredbullFixedYieldVaultFactory")) {
            factory = CredbullFixedYieldVaultFactory(deployChecker.getContractAddress("CredbullFixedYieldVaultFactory"));
        }

        vm.stopBroadcast();

        stakingVaults = new CredbullFixedYieldVault[](5);

        vm.startBroadcast(vm.envUint("OPERATOR_PRIVATE_KEY"));
        //Create staking vaults
        stakingVaults[0] =
            CredbullFixedYieldVault(factory.createVault(createStakingVaultParams(helperConfig, 10), "FixedYieldVault"));
        stakingVaults[1] =
            CredbullFixedYieldVault(factory.createVault(createStakingVaultParams(helperConfig, 20), "FixedYieldVault"));
        stakingVaults[2] =
            CredbullFixedYieldVault(factory.createVault(createStakingVaultParams(helperConfig, 30), "FixedYieldVault"));
        stakingVaults[3] =
            CredbullFixedYieldVault(factory.createVault(createStakingVaultParams(helperConfig, 40), "FixedYieldVault"));
        stakingVaults[4] =
            CredbullFixedYieldVault(factory.createVault(createStakingVaultParams(helperConfig, 50), "FixedYieldVault"));
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("ADMIN_PRIVATE_KEY"));
        for (uint256 i = 0; i < stakingVaults.length; i++) {
            stakingVaults[i].toggleWhiteListCheck();
            stakingVaults[i].setCheckMaxCap(false);
        }
        vm.stopBroadcast();

        return (factory, stakingVaults, helperConfig);
    }

    function createStakingVaultParams(HelperConfig helperConfig, uint256 _yieldPercentage)
        internal
        view
        returns (CredbullFixedYieldVault.FixedYieldVaultParams memory)
    {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        Vault.VaultParams memory _vaultParams = Vault.VaultParams({
            asset: IERC20(config.cblToken),
            shareName: "CBLStakingShares",
            shareSymbol: "sCBL",
            custodian: config.factoryParams.custodian
        });

        MaturityVault.MaturityVaultParams memory _maturityVaultParams =
            MaturityVault.MaturityVaultParams({ vault: _vaultParams });

        FixedYieldVault.ContractRoles memory _contractRoles = FixedYieldVault.ContractRoles({
            owner: config.factoryParams.owner,
            operator: config.factoryParams.operator,
            custodian: config.factoryParams.custodian
        });

        WindowPlugin.Window memory _depositWindow = WindowPlugin.Window({ opensAt: 1729468800, closesAt: 1730246400 });

        WindowPlugin.Window memory _redemptionWindow =
            WindowPlugin.Window({ opensAt: 1730246401, closesAt: 1730332800 });

        WindowPlugin.WindowPluginParams memory _windowPluginParams =
            WindowPlugin.WindowPluginParams({ depositWindow: _depositWindow, redemptionWindow: _redemptionWindow });

        WhiteListPlugin.WhiteListPluginParams memory _whiteListPluginParams = WhiteListPlugin.WhiteListPluginParams({
            whiteListProvider: vm.addr(1), // Whitelist provider not necessary for staking vaults
            depositThresholdForWhiteListing: 100e6
        });

        MaxCapPlugin.MaxCapPluginParams memory _maxCapPluginParams = MaxCapPlugin.MaxCapPluginParams({ maxCap: 100e6 });

        return FixedYieldVault.FixedYieldVaultParams({
            maturityVault: _maturityVaultParams,
            roles: _contractRoles,
            windowPlugin: _windowPluginParams,
            whiteListPlugin: _whiteListPluginParams,
            maxCapPlugin: _maxCapPluginParams,
            promisedYield: _yieldPercentage
        });
    }
}
