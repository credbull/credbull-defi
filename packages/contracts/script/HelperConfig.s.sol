//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockKYCProvider } from "../test/mocks/MockKYCProvider.sol";

struct NetworkConfig {
    address owner;
    address asset;
    string shareName;
    string shareSymbol;
    address custodian;
    address kycProvider;
    address treasury;
    address activityReward;
}

struct TimeConfig {
    uint256 firstVaultOpensAt;
    uint256 vaultClosesDuration;
}

contract HelperConfig is Script {
    NetworkConfig private activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getTimeConfig() public view returns (TimeConfig memory) {
        return TimeConfig({
            firstVaultOpensAt: vm.envUint("VAULT_OPENS_AT_TIMESTAMP"),
            vaultClosesDuration: vm.envUint("VAULT_CLOSES_DURATION_TIMESTAMP")
        });
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            asset: 0x6402c4c08C1F752Ac8c91beEAF226018ec1a27f2,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            custodian: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            kycProvider: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            treasury: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            activityReward: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
        });

        return sepoliaConfig;
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.asset != address(0)) {
            return activeNetworkConfig;
        }

        // TODO: because we dont have a real custodian, we need to fix one that we have a private key for testing.
        address custodian = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // use a owner that we have a private key for testing

        vm.startBroadcast();
        MockStablecoin usdc = new MockStablecoin(type(uint128).max);
        MockKYCProvider kycProvider = new MockKYCProvider(owner);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            asset: address(usdc),
            shareName: "Share_anv",
            shareSymbol: "SYM_anv",
            owner: owner,
            custodian: custodian,
            kycProvider: address(kycProvider),
            treasury: makeAddr("treasury"),
            activityReward: makeAddr("activityReward")
        });

        return anvilConfig;
    }
}
