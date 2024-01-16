//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address owner;
        address asset;
        string shareName;
        string shareSymbol;
        address custodian;
        address treasury;
        address activityReward;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            asset: 0x6402c4c08C1F752Ac8c91beEAF226018ec1a27f2,
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            custodian: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
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
        // use a owner that we have a private key for testing
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        vm.startBroadcast();
        MockStablecoin usdc = new MockStablecoin(type(uint128).max);
        usdc.mint(custodian, 200 ether);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            asset: address(usdc),
            shareName: "Share_anv",
            shareSymbol: "SYM_anv",
            owner: owner,
            custodian: custodian,
            treasury: makeAddr("treasury"),
            activityReward: makeAddr("activityReward")
        });

        return anvilConfig;
    }
}
