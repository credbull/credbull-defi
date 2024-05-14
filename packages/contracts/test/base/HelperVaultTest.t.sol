//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, FactoryParams } from "../../script/HelperConfig.s.sol";

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
}
