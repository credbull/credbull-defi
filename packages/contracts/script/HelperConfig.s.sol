//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";
import { MockKYCProvider } from "../test/mocks/MockKYCProvider.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";

struct FactoryParams {
    address owner;
    address operator;
}

struct NetworkConfig {
    ICredbull.VaultParams vaultParams;
    FactoryParams factoryParams;
}

contract HelperConfig is Script {
    NetworkConfig private activeNetworkConfig;
    uint256 private constant PROMISED_FIXED_YIELD = 10;

    using stdJson for string;

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

    function getSepoliaEthConfig() internal returns (NetworkConfig memory) {
        FactoryParams memory factoryParams = FactoryParams({
            owner: vm.envAddress("PUBLIC_OWNER_ADDRESS"),
            operator: vm.envAddress("PUBLIC_OPERATOR_ADDRESS")
        });

        (address usdc, address token, address kycProvider) = deployMocks(factoryParams.owner);

        // no need for vault params when using a real network
        ICredbull.VaultParams memory empty = ICredbull.VaultParams({
            asset: IERC20(usdc),
            token: IERC20(token),
            owner: address(0),
            operator: address(0),
            custodian: address(0),
            kycProvider: kycProvider,
            shareName: "",
            shareSymbol: "",
            promisedYield: 0,
            depositOpensAt: 0,
            depositClosesAt: 0,
            redemptionOpensAt: 0,
            redemptionClosesAt: 0,
            maxCap: 1e6 * 1e6
        });

        NetworkConfig memory sepoliaConfig = NetworkConfig({ factoryParams: factoryParams, vaultParams: empty });
        return sepoliaConfig;
    }

    function deployMocks(address owner) internal returns (address, address, address) {
        MockToken token;
        MockStablecoin usdc;
        MockKYCProvider kycProvider;

        bool deployMockToken;
        bool deployMockStableCoin;
        bool deployMockKycProvider;

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/output/dbdata.json");
        string memory json = vm.readFile(path);

        bytes memory mockToken = json.parseRaw(".MockToken");
        bytes memory mockStableCoin = json.parseRaw(".MockStablecoin");
        bytes memory mockKycProvider = json.parseRaw(".MockKYCProvider");

        if (mockToken.length == 0) {
            deployMockToken = true;
        }

        if (mockStableCoin.length == 0) {
            deployMockStableCoin = true;
        }

        if (mockKycProvider.length == 0) {
            deployMockKycProvider = true;
        }

        vm.startBroadcast();
        if (deployMockToken) {
            token = new MockToken(type(uint128).max);
        } else {
            console2.log("!!!!! Deployment skipped for MockStablecoin !!!!!");
        }

        if (deployMockStableCoin) {
            usdc = new MockStablecoin(type(uint128).max);
        } else {
            console2.log("!!!!! Deployment skipped for MockStablecoin !!!!!");
        }

        if (deployMockKycProvider) {
            kycProvider = new MockKYCProvider(owner);
        } else {
            console2.log("!!!!! Deployment skipped for MockKYCProvider !!!!!");
        }

        vm.stopBroadcast();

        return (address(token), address(usdc), address(kycProvider));
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
        MockToken token = new MockToken(type(uint128).max);
        MockStablecoin usdc = new MockStablecoin(type(uint128).max);
        MockKYCProvider kycProvider = new MockKYCProvider(owner);
        vm.stopBroadcast();

        ICredbull.VaultParams memory anvilVaultParams = ICredbull.VaultParams({
            asset: IERC20(usdc),
            token: IERC20(token),
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
            maxCap: 1e6 * 1e6
        });

        FactoryParams memory factoryParams = FactoryParams({
            owner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            operator: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        });

        NetworkConfig memory anvilConfig =
            NetworkConfig({ vaultParams: anvilVaultParams, factoryParams: factoryParams });

        return anvilConfig;
    }
}
