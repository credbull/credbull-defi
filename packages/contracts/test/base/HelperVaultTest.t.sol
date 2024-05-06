//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { HelperConfig, NetworkConfig, FactoryParams } from "../../script/HelperConfig.s.sol";
import { DeployMocks } from "../../script//DeployMocks.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";

/// Utility to help with testing vaults
contract HelperVaultTest is Test {
    bool private testMode = true;

    HelperConfig private helperConfig;
    NetworkConfig private networkConfig;

    address private custodianAddress;

    constructor(HelperConfig _helperConfig) {
        helperConfig = _helperConfig;
        networkConfig = helperConfig.getNetworkConfig();
    }

    /// this version is tied to Anvil - it is using Anvil's well known addresses
    function createTestVaultParams() public returns (ICredbull.VaultParams memory) {
        FactoryParams memory factoryParams = networkConfig.factoryParams;

        address custodian = makeAddr("custodianAddress");
        uint256 promisedFixedYield = helperConfig.PROMISED_FIXED_YIELD();

        // TODO: shouldn't redeploy here - need to grab from network config once added
        DeployMocks deployMocks = new DeployMocks(testMode);
        (MockToken mockToken, MockStablecoin mockStablecoin) = deployMocks.run();

        // call this after deploying the mocks - we will definitely have block transactions then
        uint256 opensAt = block.timestamp;
        uint256 closesAt = opensAt + 7 days;
        uint256 year = 365 days;

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
