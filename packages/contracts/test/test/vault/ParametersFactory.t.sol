//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { NetworkConfig } from "@script/HelperConfig.s.sol";

import { CredbullFixedYieldVaultWithUpside } from "@src/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullFixedYieldVault } from "@src/CredbullFixedYieldVault.sol";
import { MaxCapPlugIn } from "@src/plugin/MaxCapPlugIn.sol";
import { WhitelistPlugIn } from "@src/plugin/WhitelistPlugIn.sol";
import { WindowPlugIn } from "@src/plugin/WindowPlugIn.sol";
import { UpsideVault } from "@src/vault/UpsideVault.sol";
import { FixedYieldVault } from "@src/vault/FixedYieldVault.sol";
import { MaturityVault } from "@src/vault/MaturityVault.sol";
import { Vault } from "@src/vault/Vault.sol";

import { MockVault } from "@test/test/mock/vault/MockVault.t.sol";

contract ParametersFactory is Test {
    uint256 private constant PROMISED_FIXED_YIELD = 10;
    NetworkConfig private networkConfig;

    constructor(NetworkConfig memory _networkConfig) {
        networkConfig = _networkConfig;
    }

    function createVaultParameters() public returns (Vault.VaultParameters memory params) {
        address custodian = makeAddr("custodianAddress");

        params = Vault.VaultParameters({
            asset: networkConfig.usdcToken,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            custodian: custodian
        });
    }

    function createUpsideVaultParameters()
        public
        returns (CredbullFixedYieldVaultWithUpside.UpsideVaultParameters memory params)
    {
        params = UpsideVault.UpsideVaultParameters({
            fixedYieldVault: createFixedYieldVaultParameters(),
            cblToken: networkConfig.cblToken,
            collateralPercentage: 20_00
        });
    }

    function createFixedYieldVaultParameters()
        public
        returns (FixedYieldVault.FixedYieldVaultParameters memory params)
    {
        params = FixedYieldVault.FixedYieldVaultParameters({
            maturityVault: createMaturityVaultParameters(),
            roles: createContractRoles(),
            windowPlugIn: createWindowPlugInParameters(),
            whitelistPlugIn: createWhitelistPlugInParameters(),
            maxCapPlugIn: createMaxCapPlugInParameters()
        });
    }

    function createMaturityVaultParameters() public returns (MaturityVault.MaturityVaultParameters memory params) {
        params = MaturityVault.MaturityVaultParameters({
            vault: createVaultParameters(),
            promisedYield: PROMISED_FIXED_YIELD
        });
    }

    function createMaxCapPlugInParameters() public pure returns (MaxCapPlugIn.MaxCapPlugInParameters memory params) {
        params = MaxCapPlugIn.MaxCapPlugInParameters({ maxCap: 1e6 * 1e6 });
    }

    function createWhitelistPlugInParameters()
        public
        returns (WhitelistPlugIn.WhitelistPlugInParameters memory params)
    {
        params = WhitelistPlugIn.WhitelistPlugInParameters({
            kycProvider: makeAddr("kycProviderAddress"),
            depositThresholdForWhitelisting: 1000e6
        });
    }

    function createWindowPlugInParameters() public view returns (WindowPlugIn.WindowPlugInParameters memory params) {
        uint256 opensAt = block.timestamp;
        uint256 closesAt = opensAt + 7 days;
        uint256 year = 365 days;

        WindowPlugIn.Window memory depositWindow = WindowPlugIn.Window({ opensAt: opensAt, closesAt: closesAt });
        WindowPlugIn.Window memory redemptionWindow =
            WindowPlugIn.Window({ opensAt: opensAt + year, closesAt: closesAt + year });

        params =
            WindowPlugIn.WindowPlugInParameters({ depositWindow: depositWindow, redemptionWindow: redemptionWindow });
    }

    function createContractRoles() public returns (FixedYieldVault.ContractRoles memory roles) {
        roles = FixedYieldVault.ContractRoles({
            owner: networkConfig.factoryParams.owner,
            operator: networkConfig.factoryParams.operator,
            custodian: makeAddr("custodianAddress")
        });
    }
}
