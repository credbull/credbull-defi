//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { NetworkConfig } from "@script/HelperConfig.s.sol";

import { MaxCapPlugin } from "@credbull/plugin/MaxCapPlugin.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";
import { WindowPlugin } from "@credbull/plugin/WindowPlugin.sol";
import { UpsideVault } from "@credbull/vault/UpsideVault.sol";
import { FixedYieldVault } from "@credbull/vault/FixedYieldVault.sol";
import { MaturityVault } from "@credbull/vault/MaturityVault.sol";
import { Vault } from "@credbull/vault/Vault.sol";

/**
 * @notice A test utility for creating 'Params' instances for the various [Vault] types.
 */
contract ParamsFactory is Test {
    uint256 private constant PROMISED_FIXED_YIELD = 10;
    NetworkConfig private networkConfig;

    constructor(NetworkConfig memory _networkConfig) {
        networkConfig = _networkConfig;
    }

    function createVaultParams() public returns (Vault.VaultParams memory params) {
        address custodian = makeAddr("custodianAddress");

        params = Vault.VaultParams({
            asset: networkConfig.usdcToken,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            custodian: custodian
        });
    }

    function createUpsideVaultParams() public returns (UpsideVault.UpsideVaultParams memory params) {
        params = UpsideVault.UpsideVaultParams({
            fixedYieldVault: createFixedYieldVaultParams(),
            cblToken: networkConfig.cblToken,
            collateralPercentage: 20_00
        });
    }

    function createFixedYieldVaultParams() public returns (FixedYieldVault.FixedYieldVaultParams memory params) {
        params = FixedYieldVault.FixedYieldVaultParams({
            maturityVault: createMaturityVaultParams(),
            roles: createContractRoles(),
            windowPlugin: createWindowPluginParams(),
            whiteListPlugin: createWhiteListPluginParams(),
            maxCapPlugin: createMaxCapPluginParams(),
            promisedYield: PROMISED_FIXED_YIELD
        });
    }

    function createMaturityVaultParams() public returns (MaturityVault.MaturityVaultParams memory params) {
        params = MaturityVault.MaturityVaultParams({ vault: createVaultParams() });
    }

    function createMaxCapPluginParams() public pure returns (MaxCapPlugin.MaxCapPluginParams memory params) {
        params = MaxCapPlugin.MaxCapPluginParams({ maxCap: 1e6 * 1e6 });
    }

    function createWhiteListPluginParams() public returns (WhiteListPlugin.WhiteListPluginParams memory params) {
        params = WhiteListPlugin.WhiteListPluginParams({
            whiteListProvider: makeAddr("whiteListProviderAddress"),
            depositThresholdForWhiteListing: 1000e6
        });
    }

    function createWindowPluginParams() public view returns (WindowPlugin.WindowPluginParams memory params) {
        uint256 opensAt = block.timestamp;
        uint256 closesAt = opensAt + 7 days;
        uint256 year = 365 days;

        WindowPlugin.Window memory depositWindow = WindowPlugin.Window({ opensAt: opensAt, closesAt: closesAt });
        WindowPlugin.Window memory redemptionWindow =
            WindowPlugin.Window({ opensAt: opensAt + year, closesAt: closesAt + year });

        params = WindowPlugin.WindowPluginParams({ depositWindow: depositWindow, redemptionWindow: redemptionWindow });
    }

    function createContractRoles() public returns (FixedYieldVault.ContractRoles memory roles) {
        roles = FixedYieldVault.ContractRoles({
            owner: networkConfig.factoryParams.owner,
            operator: networkConfig.factoryParams.operator,
            custodian: makeAddr("custodianAddress")
        });
    }
}
