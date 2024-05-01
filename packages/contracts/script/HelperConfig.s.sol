//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { DeployMocks } from "./DeployMocks.s.sol";

import { ICredbull } from "../src/interface/ICredbull.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";

struct FactoryParams {
    address owner;
    address operator;
    uint256 collateralPercentage;
}

struct NetworkConfig {
    ICredbull.VaultParams vaultParams;
    FactoryParams factoryParams;
}

contract HelperConfig is Script {
    bool private test;
    NetworkConfig private activeNetworkConfig;
    uint256 private constant PROMISED_FIXED_YIELD = 10;
    uint256 private constant COLLATERAL_PERCENTAGE = 20_00;

    using stdJson for string;

    constructor(bool _test) {
        test = _test;
        if (block.chainid == 421614 || block.chainid == 80001) {
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
            operator: vm.envAddress("PUBLIC_OPERATOR_ADDRESS"),
            collateralPercentage: vm.envUint("COLLATERAL_PERCENTAGE")
        });

        DeployMocks deployMocks = new DeployMocks();
        (address token, address usdc) = deployMocks.deployMocksOrSkipIfPreviouslyDeployed();

        // no need for vault params when using a real network
        ICredbull.VaultParams memory empty = ICredbull.VaultParams({
            asset: IERC20(usdc),
            token: IERC20(token),
            owner: address(0),
            operator: address(0),
            custodian: address(0),
            kycProvider: address(0),
            shareName: "",
            shareSymbol: "",
            promisedYield: 0,
            depositOpensAt: 0,
            depositClosesAt: 0,
            redemptionOpensAt: 0,
            redemptionClosesAt: 0,
            maxCap: 1e6 * 1e6,
            depositThresholdForWhitelisting: 1000e6
        });

        NetworkConfig memory sepoliaConfig = NetworkConfig({ factoryParams: factoryParams, vaultParams: empty });
        return sepoliaConfig;
    }

    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.vaultParams.asset) != address(0)) {
            return activeNetworkConfig;
        }

        // TODO: because we dont have a real custodian, we need to fix one that we have a private key for testing.
        address custodian = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        address owner = test ? 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 : vm.envAddress("PUBLIC_OWNER_ADDRESS"); // use a owner that we have a private key for testing
        address operator = test ? 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 : vm.envAddress("PUBLIC_OPERATOR_ADDRESS");

        (uint256 opensAt, uint256 closesAt) = getTimeConfig();
        uint256 year = 365 days;

        DeployMocks deployMocks = new DeployMocks();
        (address token, address usdc) = deployMocks.deployMocksOrSkipIfPreviouslyDeployed();

        ICredbull.VaultParams memory anvilVaultParams = ICredbull.VaultParams({
            asset: IERC20(usdc),
            token: IERC20(token),
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: owner,
            operator: operator,
            custodian: custodian,
            kycProvider: address(0),
            promisedYield: PROMISED_FIXED_YIELD,
            depositOpensAt: opensAt,
            depositClosesAt: closesAt,
            redemptionOpensAt: opensAt + year,
            redemptionClosesAt: closesAt + year,
            maxCap: 1e6 * 1e6,
            depositThresholdForWhitelisting: 1000e6
        });

        FactoryParams memory factoryParams =
            FactoryParams({ owner: owner, operator: operator, collateralPercentage: COLLATERAL_PERCENTAGE });

        NetworkConfig memory anvilConfig =
            NetworkConfig({ vaultParams: anvilVaultParams, factoryParams: factoryParams });

        return anvilConfig;
    }
}
