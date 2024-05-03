//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";

import { DeployMocks } from "./DeployMocks.s.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";

struct FactoryParams {
    address owner;
    address operator;
    uint256 collateralPercentage;
}

// TODO - add other contract addresses here, including USDC
struct NetworkConfig {
    FactoryParams factoryParams;
}

struct ContractRoles {
    address owner;
    address operator;
    address[] additionalRoles;
}

/// @author
/// Each chain has different addresses for contracts such as USDC and Safe
/// The purpose of this contract is to centralize any chain-specific config and code into one place
/// This is the only place in the code that should know about different chains
/// This should be the only place where we retrieve variables from the Environment ???
/// TODO: move the test specific helpers into the test package
/// @title Helper to centralize any chain-specific config and code into one place
contract HelperConfig is Script {
    NetworkConfig private activeNetworkConfig;
    uint256 public constant PROMISED_FIXED_YIELD = 10;
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

    // TODO: create sensible defaults for these in case no params set
    function getTimeConfig() public view returns (uint256 opensAt, uint256 closesAt) {
        opensAt = vm.envUint("VAULT_OPENS_AT_TIMESTAMP");
        closesAt = opensAt + vm.envUint("VAULT_CLOSES_DURATION_TIMESTAMP");
    }

    function getSepoliaEthConfig() internal view returns (NetworkConfig memory) {
        FactoryParams memory factoryParams = FactoryParams({
            owner: vm.envAddress("PUBLIC_OWNER_ADDRESS"),
            operator: vm.envAddress("PUBLIC_OPERATOR_ADDRESS"),
            collateralPercentage: vm.envUint("COLLATERAL_PERCENTAGE")
        });

        NetworkConfig memory sepoliaConfig = NetworkConfig({ factoryParams: factoryParams });

        return sepoliaConfig;
    }

    // TODO: remove the VaultParams!  We should create Vaults using Factories.
    /// Create Config for Anvil (local) chain
    /// @return Network config and VaultParams template
    function getAnvilEthConfig() private returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.factoryParams.operator) != address(0)) {
            return (activeNetworkConfig);
        }

        ContractRoles memory contractRoles = createRolesFromMnemonic(getAnvilMnemonic());

        FactoryParams memory factoryParams = FactoryParams({
            owner: contractRoles.owner,
            operator: contractRoles.operator,
            collateralPercentage: COLLATERAL_PERCENTAGE
        });

        NetworkConfig memory anvilConfig = NetworkConfig({ factoryParams: factoryParams });

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
    function getAnvilMnemonic() public returns (string memory) {
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
