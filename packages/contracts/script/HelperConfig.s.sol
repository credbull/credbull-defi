//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { DeployMockToken, DeployMockStablecoin } from "./DeployMocks.s.sol";

import { ICredbull } from "../src/interface/ICredbull.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct FactoryParams {
    address owner;
    address operator;
    uint256 collateralPercentage;
}

struct NetworkConfig {
    ICredbull.VaultParams vaultParams; // TODO: remove this, only required for Testing.  Factory should be used to create Vaults.
    FactoryParams factoryParams;
}

struct ContractRoles {
    address owner;
    address operator;
    address[] additionalRoles;
}

contract HelperConfig is Script {
    NetworkConfig private activeNetworkConfig;
    uint256 private constant PROMISED_FIXED_YIELD = 10;
    uint256 private constant COLLATERAL_PERCENTAGE = 20_00;

    bool private testMode = false;

    constructor(bool _test) {
        testMode = _test;

        if (block.chainid == 421614 || block.chainid == 80001 || block.chainid == 84532) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilEthConfig();
        } else {
            revert(string.concat("Unsupported chain with chainId ", vm.toString(block.chainid)));
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

        DeployMockToken deployMockToken = new DeployMockToken();
        address tokenAddress = deployMockToken.deployIfNeeded();

        DeployMockStablecoin deployMockStablecoin = new DeployMockStablecoin();
        address stablecoinAddress = deployMockStablecoin.deployIfNeeded();

        // no need for vault params when using a real network
        ICredbull.VaultParams memory empty = ICredbull.VaultParams({
            asset: IERC20(stablecoinAddress),
            token: IERC20(tokenAddress),
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

    /// Create Contract Roles from a mnemonic passphrase
    /// @return ContractRoles based on the phassphrase
    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.vaultParams.asset) != address(0)) {
            return activeNetworkConfig;
        }

        (uint256 opensAt, uint256 closesAt) = getTimeConfig();
        uint256 year = 365 days;

        DeployMockToken deployMockToken = new DeployMockToken();
        address tokenAddress = testMode ? deployMockToken.deployAlways() : deployMockToken.deployIfNeeded();

        DeployMockStablecoin deployMockStablecoin = new DeployMockStablecoin();
        address stablecoinAddress =
            testMode ? deployMockStablecoin.deployAlways() : deployMockStablecoin.deployIfNeeded();

        ContractRoles memory contractRoles = createRolesFromMnemonic(getAnvilMnemonic());

        ICredbull.VaultParams memory anvilVaultParams = ICredbull.VaultParams({
            asset: IERC20(stablecoinAddress),
            token: IERC20(tokenAddress),
            shareName: "Share_sep",
            shareSymbol: "SYM_sep",
            owner: contractRoles.owner,
            operator: contractRoles.operator,
            custodian: contractRoles.additionalRoles[0],
            kycProvider: address(0),
            promisedYield: PROMISED_FIXED_YIELD,
            depositOpensAt: opensAt,
            depositClosesAt: closesAt,
            redemptionOpensAt: opensAt + year,
            redemptionClosesAt: closesAt + year,
            maxCap: 1e6 * 1e6,
            depositThresholdForWhitelisting: 1000e6
        });

        FactoryParams memory factoryParams = FactoryParams({
            owner: contractRoles.owner,
            operator: contractRoles.operator,
            collateralPercentage: COLLATERAL_PERCENTAGE
        });

        NetworkConfig memory anvilConfig =
            NetworkConfig({ vaultParams: anvilVaultParams, factoryParams: factoryParams });

        return anvilConfig;
    }

    /// Create Contract Roles from a mnemonic passphrase
    /// @return ContractRoles based on the phassphrase
    function createRolesFromMnemonic(string memory mnemonic) public pure returns (ContractRoles memory) {
        address owner = vm.addr(vm.deriveKey(mnemonic, 0)); // account 0
        address operator = vm.addr(vm.deriveKey(mnemonic, 1)); // account 1
        address custodian = vm.addr(vm.deriveKey(mnemonic, 2)); // account 2

        address[] memory additionalRoles = new address[](1); // Create an array of addresses
        additionalRoles[0] = custodian; // Add the custodian address to the array

        ContractRoles memory contractRoles =
            ContractRoles({ owner: owner, operator: operator, additionalRoles: additionalRoles });

        return contractRoles;
    }

    /// Get the Anvil (local) mnemonic passphrase
    /// @return the mnemonic passphrase
    function getAnvilMnemonic() internal returns (string memory) {
        // if anvil was run, get the mnemonic from the config output
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/localhost.json");

        if (vm.exists(path)) {
            string memory json = vm.readFile(path);
            bytes memory mnemonicBytes = vm.parseJson(json, ".wallet.mnemonic");

            return abi.decode(mnemonicBytes, (string));
        } else {
            // Anvil not run previously - use the test mnemonic
            return "test test test test test test test test test test test junk";
        }
    }
}
