//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, FactoryParams } from "../../script/HelperConfig.s.sol";
import { CredbullBaseVault } from "../mocks/vaults/CredbullBaseVaultMock.m.sol";
import { CredbullFixedYieldVaultWithUpside } from "../../src/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { MaxCapVaultMock } from "../mocks/vaults/MaxCapVaultMock.m.sol";
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

    /// this version is tied to Anvil - it is using Anvil's well known addresses
    function createTestVaultParams() public returns (ICredbull.VaultParams memory) {
        address custodian = makeAddr("custodianAddress");

        return createTestVaultParams(custodian, address(0));
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

    /// this version is tied to Anvil - it is using Anvil's well known addresses
    function createTestVaultParams(address custodian, address kycProvider)
        public
        view
        returns (ICredbull.VaultParams memory)
    {
        FactoryParams memory factoryParams = networkConfig.factoryParams;

        uint256 promisedFixedYield = PROMISED_FIXED_YIELD;

        // call this after deploying the mocks - we will definitely have block transactions then
        uint256 opensAt = block.timestamp;
        uint256 closesAt = opensAt + 7 days;
        uint256 year = 365 days;

        ICredbull.VaultParams memory testVaultParams = ICredbull.VaultParams({
            asset: networkConfig.usdcToken,
            token: networkConfig.cblToken,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: factoryParams.owner,
            operator: factoryParams.operator,
            custodian: custodian,
            kycProvider: kycProvider,
            promisedYield: promisedFixedYield,
            depositOpensAt: opensAt,
            depositClosesAt: closesAt,
            redemptionOpensAt: opensAt + year,
            redemptionClosesAt: closesAt + year,
            maxCap: 1e6 * 1e6,
            depositThresholdForWhitelisting: 1000e6
        });

        return testVaultParams;
    }

    function toString(ICredbull.VaultParams memory params) public pure returns (string memory) {
        string memory part1 = string.concat(
            "\nVaultParams {\n",
            "  owner: ",
            vm.toString(params.owner),
            ",\n",
            "  operator: ",
            vm.toString(params.operator),
            ",\n",
            "  asset: ",
            vm.toString(address(params.asset)),
            ",\n",
            "  token: ",
            vm.toString(address(params.token)),
            ",\n",
            "  shareName: ",
            params.shareName,
            ",\n",
            "  shareSymbol: ",
            params.shareSymbol,
            ",\n",
            "  promisedYield: ",
            vm.toString(params.promisedYield),
            ",\n"
        );

        string memory part2 = string.concat(
            "  depositOpensAt: ",
            vm.toString(params.depositOpensAt),
            ",\n",
            "  depositClosesAt: ",
            vm.toString(params.depositClosesAt),
            ",\n",
            "  redemptionOpensAt: ",
            vm.toString(params.redemptionOpensAt),
            ",\n",
            "  redemptionClosesAt: ",
            vm.toString(params.redemptionClosesAt),
            ",\n",
            "  custodian: ",
            vm.toString(params.custodian),
            ",\n"
        );

        string memory part3 = string.concat(
            "  kycProvider: ",
            vm.toString(params.kycProvider),
            ",\n",
            "  maxCap: ",
            vm.toString(params.maxCap),
            ",\n",
            "  depositThresholdForWhitelisting: ",
            vm.toString(params.depositThresholdForWhitelisting),
            "\n",
            "}"
        );

        return string.concat(part1, part2, part3);
    }
}
