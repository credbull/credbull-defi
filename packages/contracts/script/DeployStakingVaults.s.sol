//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

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

contract DeployStakingVaults is Script {
    bool private isTestMode;

    function runTest()
        public
        returns (
            CredbullFixedYieldVaultFactory factory,
            CredbullFixedYieldVault stakingVault,
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
            CredbullFixedYieldVault stakingVault,
            HelperConfig helperConfig
        )
    {
        helperConfig = new HelperConfig(isTestMode);

        vm.startBroadcast();
        stakingVault = new CredbullFixedYieldVault(createStakingVaultParams(helperConfig, 50));
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("ADMIN_PRIVATE_KEY"));

        stakingVault.toggleWhiteListCheck();
        stakingVault.setCheckMaxCap(false);

        vm.stopBroadcast();

        return (factory, stakingVault, helperConfig);
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

        WindowPlugin.Window memory _depositWindow = WindowPlugin.Window({ opensAt: 1730973600, closesAt: 1732320000 });

        WindowPlugin.Window memory _redemptionWindow =
            WindowPlugin.Window({ opensAt: 1732320000, closesAt: 1734912000 });

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
