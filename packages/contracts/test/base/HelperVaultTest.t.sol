//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, FactoryParams } from "../../script/HelperConfig.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function createBaseVaultTestParams() public returns (ICredbull.BaseVaultParams memory params) {
        address custodian = makeAddr("custodianAddress");

        params = ICredbull.BaseVaultParams({
            asset: networkConfig.usdcToken,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            custodian: custodian
        });
    }

    function createFixedYieldWithUpsideVaultParams() public returns (ICredbull.UpsideVaultParams memory params) {
        params = ICredbull.UpsideVaultParams({
            fixedYieldVaultParams: createFixedYieldVaultParams(),
            cblToken: networkConfig.cblToken,
            collateralPercentage: 20_00
        });
    }

    function createFixedYieldVaultParams() public returns (ICredbull.FixedYieldVaultParams memory params) {
        params = ICredbull.FixedYieldVaultParams({
            baseVaultParams: createBaseVaultTestParams(),
            contractRoles: createContractRoles(),
            windowVaultParams: createWindowVaultParams(),
            kycParams: createKycParams(),
            maxCapParams: createMaxCapParams(),
            promisedYield: PROMISED_FIXED_YIELD
        });
    }

    function createMaturityVaultTestParams() public returns (ICredbull.FixedYieldVaultParams memory params) {
        return createFixedYieldVaultParams();
    }

    function createMaxCapParams() public pure returns (ICredbull.MaxCapParams memory params) {
        params = ICredbull.MaxCapParams({ maxCap: 1e6 * 1e6 });
    }

    function createKycParams() public returns (ICredbull.KycParams memory params) {
        params = ICredbull.KycParams({
            kycProvider: makeAddr("kycProviderAddress"),
            depositThresholdForWhitelisting: 1000e6
        });
    }

    function createWindowVaultParams() public view returns (ICredbull.WindowVaultParams memory params) {
        uint256 opensAt = block.timestamp;
        uint256 closesAt = opensAt + 7 days;
        uint256 year = 365 days;

        ICredbull.WindowParams memory depositWindow = ICredbull.WindowParams({ opensAt: opensAt, closesAt: closesAt });

        ICredbull.WindowParams memory matureWindow =
            ICredbull.WindowParams({ opensAt: opensAt + year, closesAt: closesAt + year });

        params = ICredbull.WindowVaultParams({ depositWindow: depositWindow, matureWindow: matureWindow });
    }

    function createContractRoles() public returns (ICredbull.ContractRoles memory roles) {
        roles = ICredbull.ContractRoles({
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
