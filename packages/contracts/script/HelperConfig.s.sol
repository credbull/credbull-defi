//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockKYCProvider } from "../test/mocks/MockKYCProvider.sol";
import { MockToken } from "../test/mocks/MockToken.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct FactoryParams {
    address owner;
    address operator;
}

struct NetworkConfig {
    ICredbull.VaultParams vaultParams;
    ICredbull.Entities entities;
    FactoryParams factoryParams;
}

contract HelperConfig is Script {
    NetworkConfig private activeNetworkConfig;
    uint256 private constant PROMISED_FIXED_YIELD = 10;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getTimeConfig() internal view returns (uint256 opensAt, uint256 closesAt) {
        opensAt = vm.envUint("VAULT_OPENS_AT_TIMESTAMP");
        closesAt = opensAt + vm.envUint("VAULT_CLOSES_DURATION_TIMESTAMP");
    }

    function getSepoliaEthConfig() internal view returns (NetworkConfig memory) {
        (uint256 opensAt, uint256 closesAt) = getTimeConfig();
        uint256 year = 365 days;

        //TODO: Replace with actual addresses to be used on testnet
        ICredbull.VaultParams memory sepoliaVaultParams = ICredbull.VaultParams({
            asset: IERC20(0x6402c4c08C1F752Ac8c91beEAF226018ec1a27f2),
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            operator: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            custodian: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            kycProvider: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            promisedYield: PROMISED_FIXED_YIELD,
            depositOpensAt: opensAt,
            depositClosesAt: closesAt,
            redemptionOpensAt: opensAt + year,
            redemptionClosesAt: closesAt + year,
            treasury: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            activityReward: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });

        //TODO: Replace with actual addresses to be used on testnet
        ICredbull.Entities memory entities = ICredbull.Entities({
            activityReward: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            custodian: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            kycProvider: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            treasury: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });

        FactoryParams memory factoryParams = FactoryParams({
            owner: vm.envAddress("PUBLIC_OWNER_ADDRESS"),
            operator: vm.envAddress("PUBLIC_OPERATOR_ADDRESS")
        });

        NetworkConfig memory sepoliaConfig =
            NetworkConfig({ vaultParams: sepoliaVaultParams, entities: entities, factoryParams: factoryParams });

        return sepoliaConfig;
    }

    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.vaultParams.asset) != address(0)) {
            return activeNetworkConfig;
        }

        // TODO: because we dont have a real custodian, we need to fix one that we have a private key for testing.
        address custodian = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // use a owner that we have a private key for testing

        (uint256 opensAt, uint256 closesAt) = getTimeConfig();
        uint256 year = 365 days;

        vm.startBroadcast();
        MockStablecoin usdc = new MockStablecoin(type(uint128).max);
        MockToken token = new MockToken(type(uint128).max);
        MockKYCProvider kycProvider = new MockKYCProvider(owner);
        vm.stopBroadcast();

        ICredbull.VaultParams memory anvilVaultParams = ICredbull.VaultParams({
            asset: IERC20(usdc),
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: owner,
            operator: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            custodian: custodian,
            kycProvider: address(kycProvider),
            promisedYield: PROMISED_FIXED_YIELD,
            depositOpensAt: opensAt,
            depositClosesAt: closesAt,
            redemptionOpensAt: opensAt + year,
            redemptionClosesAt: closesAt + year,
            treasury: makeAddr("treasury"),
            activityReward: makeAddr("activity")
        });

        ICredbull.Entities memory entities = ICredbull.Entities({
            activityReward: makeAddr("activityReward"),
            custodian: custodian,
            kycProvider: address(kycProvider),
            treasury: makeAddr("treasury")
        });

        FactoryParams memory factoryParams = FactoryParams({
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            operator: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        });

        NetworkConfig memory anvilConfig =
            NetworkConfig({ vaultParams: anvilVaultParams, entities: entities, factoryParams: factoryParams });

        return anvilConfig;
    }
}
