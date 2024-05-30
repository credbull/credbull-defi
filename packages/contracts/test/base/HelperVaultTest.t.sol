//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { NetworkConfig } from "../../script/HelperConfig.s.sol";
import { CredbullBaseVault } from "../mocks/vaults/CredbullBaseVaultMock.m.sol";
import { CredbullFixedYieldVaultWithUpside } from "../../src/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { MaxCapPlugIn } from "../../src/plugins/MaxCapPlug.sol";
import { WhitelistPlugIn } from "../../src/plugins/WhitelistPlugIn.sol";
import { WindowPlugIn } from "../../src/plugins/WindowPlugIn.sol";
import { UpsideVault } from "../../src/vaults/UpsideVault.sol";
import { FixedYieldVault } from "../../src/vaults/FixedYieldVault.sol";
import { MaturityVault } from "../../src/extensions/MaturityVault.sol";

/// Utility to help with testing vaults
contract HelperVaultTest is Test {
    uint256 private constant PROMISED_FIXED_YIELD = 10;
    NetworkConfig private networkConfig;

    constructor(NetworkConfig memory _networkConfig) {
        networkConfig = _networkConfig;
    }

    function createBaseVaultTestParams() public returns (CredbullBaseVault.BaseVaultParams memory params) {
        address custodian = makeAddr("custodianAddress");

        params = CredbullBaseVault.BaseVaultParams({
            asset: networkConfig.usdcToken,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            custodian: custodian
        });
    }

    function createFixedYieldWithUpsideVaultParams()
        public
        returns (CredbullFixedYieldVaultWithUpside.UpsideVaultParams memory params)
    {
        params = UpsideVault.UpsideVaultParams({
            fixedYieldVaultParams: createFixedYieldVaultParams(),
            cblToken: networkConfig.cblToken,
            collateralPercentage: 20_00
        });
    }

    function createFixedYieldVaultParams()
        public
        returns (CredbullFixedYieldVault.FixedYieldVaultParams memory params)
    {
        params = FixedYieldVault.FixedYieldVaultParams({
            maturityVaultParams: createMaturityVaultTestParams(),
            contractRoles: createContractRoles(),
            windowVaultParams: createWindowVaultParams(),
            kycParams: createKycParams(),
            maxCapParams: createMaxCapParams()
        });
    }

    function createMaturityVaultTestParams() public returns (MaturityVault.MaturityVaultParams memory params) {
        params = MaturityVault.MaturityVaultParams({
            baseVaultParams: createBaseVaultTestParams(),
            promisedYield: PROMISED_FIXED_YIELD
        });
    }

    function createMaxCapParams() public pure returns (MaxCapPlugIn.MaxCapParams memory params) {
        params = MaxCapPlugIn.MaxCapParams({ maxCap: 1e6 * 1e6 });
    }

    function createKycParams() public returns (WhitelistPlugIn.KycParams memory params) {
        params = WhitelistPlugIn.KycParams({
            kycProvider: makeAddr("kycProviderAddress"),
            depositThresholdForWhitelisting: 1000e6
        });
    }

    function createWindowVaultParams() public view returns (WindowPlugIn.WindowVaultParams memory params) {
        uint256 opensAt = block.timestamp;
        uint256 closesAt = opensAt + 7 days;
        uint256 year = 365 days;

        WindowPlugIn.WindowParams memory depositWindow =
            WindowPlugIn.WindowParams({ opensAt: opensAt, closesAt: closesAt });

        WindowPlugIn.WindowParams memory matureWindow =
            WindowPlugIn.WindowParams({ opensAt: opensAt + year, closesAt: closesAt + year });

        params = WindowPlugIn.WindowVaultParams({ depositWindow: depositWindow, matureWindow: matureWindow });
    }

    function createContractRoles() public returns (CredbullBaseVault.ContractRoles memory roles) {
        roles = CredbullBaseVault.ContractRoles({
            owner: networkConfig.factoryParams.owner,
            operator: networkConfig.factoryParams.operator,
            custodian: makeAddr("custodianAddress")
        });
    }
}
