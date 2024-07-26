// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { MaxCapPlugin } from "@credbull/plugin/MaxCapPlugin.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";
import { WindowPlugin } from "@credbull/plugin/WindowPlugin.sol";
import { UpsideVault } from "@credbull/vault/UpsideVault.sol";
import { FixedYieldVault } from "@credbull/vault/FixedYieldVault.sol";
import { MaturityVault } from "@credbull/vault/MaturityVault.sol";
import { Vault } from "@credbull/vault/Vault.sol";

import { VaultsConfigured } from "@script/Configured.s.sol";

/// @notice A test utility for creating 'Params' instances for the various [Vault] types.
contract ParamsFactory is Test, VaultsConfigured {
    uint256 private constant PROMISED_FIXED_YIELD = 10;

    ERC20 private usdc;
    ERC20 private cbl;

    constructor(ERC20 _usdc, ERC20 _cbl) {
        usdc = _usdc;
        cbl = _cbl;
    }

    function createVaultParams() public view returns (Vault.VaultParams memory) {
        return Vault.VaultParams({ asset: usdc, shareName: "Shares", shareSymbol: "SHS", custodian: custodian() });
    }

    function createUpsideVaultParams() public returns (UpsideVault.UpsideVaultParams memory params) {
        params = UpsideVault.UpsideVaultParams({
            fixedYieldVault: createFixedYieldVaultParams(),
            cblToken: cbl,
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

    function createMaturityVaultParams() public view returns (MaturityVault.MaturityVaultParams memory params) {
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

    function createContractRoles() public view returns (FixedYieldVault.ContractRoles memory) {
        return FixedYieldVault.ContractRoles({ owner: owner(), operator: operator(), custodian: custodian() });
    }
}
