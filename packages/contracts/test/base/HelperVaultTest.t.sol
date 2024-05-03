//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ICredbull } from "../../src/interface/ICredbull.sol";
import { HelperConfig, NetworkConfig, FactoryParams, ContractRoles } from "../../script/HelperConfig.s.sol";
import { DeployMocks } from "../../script//DeployMocks.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";

/// Utility to help with testing vaults
contract HelperVaultTest {
    bool private testMode = true;

    HelperConfig private helperConfig;
    NetworkConfig private networkConfig;

    constructor(HelperConfig _helperConfig) {
        helperConfig = _helperConfig;
        networkConfig = helperConfig.getNetworkConfig();
    }

    /// this version is tied to Anvil - it is using Anvil's well known addresses
    function createAnvilTestVaultParams() public returns (ICredbull.VaultParams memory) {
        ContractRoles memory contractRoles = helperConfig.createRolesFromMnemonic(helperConfig.getAnvilMnemonic());

        address cutodian = contractRoles.additionalRoles[0];

        return createTestVaultParams(cutodian);
    }

    function createTestVaultParams(address custodian) public returns (ICredbull.VaultParams memory) {
        FactoryParams memory factoryParams = networkConfig.factoryParams;

        uint256 promisedFixedYield = helperConfig.PROMISED_FIXED_YIELD();

        (uint256 opensAt, uint256 closesAt) = helperConfig.getTimeConfig();
        uint256 year = 365 days;

        // TODO: shouldn't redeploy here - need to grab from network config once added
        DeployMocks deployMocks = new DeployMocks(testMode);
        (MockToken mockToken, MockStablecoin mockStablecoin) = deployMocks.run();

        ICredbull.VaultParams memory testVaultParams = ICredbull.VaultParams({
            asset: mockStablecoin,
            token: mockToken,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: factoryParams.owner,
            operator: factoryParams.operator,
            custodian: custodian,
            kycProvider: address(0),
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
