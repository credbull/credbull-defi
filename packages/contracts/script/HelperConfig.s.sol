//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { DeployMocks } from "./DeployMocks.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct FactoryParams {
    address owner;
    address operator;
    uint256 collateralPercentage; // TODO - is this required or can we remove it?
}

// TODO - add other contract addresses here, including USDC
struct NetworkConfig {
    FactoryParams factoryParams;
    IERC20 usdcToken;
    IERC20 cblToken;
}

/// @title Helper to centralize any chain-specific config and code into one place
/// Each chain has different addresses for contracts such as USDC and (Gnosis) Safe
/// This is the only place in the contract code that knows about different chains and environment settings
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

    /// Create Config for Anvil (local) chain
    /// @return Network config will chain specific config
    function getSepoliaEthConfig() internal returns (NetworkConfig memory) {
        uint256 collateralPercentage = vm.envOr("COLLATERAL_PERCENTAGE", COLLATERAL_PERCENTAGE);

        FactoryParams memory factoryParams = FactoryParams({
            owner: vm.envAddress("PUBLIC_OWNER_ADDRESS"),
            operator: vm.envAddress("PUBLIC_OPERATOR_ADDRESS"),
            collateralPercentage: collateralPercentage
        });

        // TODO - replace this with USDC and CBL actual contract addresses
        DeployMocks deployMocks = new DeployMocks(testMode);
        (IERC20 mockToken, IERC20 mockStablecoin) = deployMocks.run();

        NetworkConfig memory sepoliaConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: mockStablecoin, cblToken: mockToken });

        return sepoliaConfig;
    }

    /// Create Config for Anvil (local) chain
    /// @return Network config will chain specific config
    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.factoryParams.operator) != address(0)) {
            return (activeNetworkConfig);
        }

        address[] memory contractRoles = deriveKeys(getAnvilMnemonic());

        uint256 collateralPercentage = vm.envOr("COLLATERAL_PERCENTAGE", COLLATERAL_PERCENTAGE);

        FactoryParams memory factoryParams = FactoryParams({
            owner: contractRoles[0],
            operator: contractRoles[1],
            collateralPercentage: collateralPercentage
        });

        DeployMocks deployMocks = new DeployMocks(testMode);
        (IERC20 mockToken, IERC20 mockStablecoin) = deployMocks.run();

        NetworkConfig memory anvilConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: mockStablecoin, cblToken: mockToken });

        return anvilConfig;
    }

    /// Derive keys from a mnemonic
    /// @return Keys from the mnemonic
    function deriveKeys(string memory mnemonic) internal pure returns (address[] memory) {
        address[] memory walletKeys = new address[](10); // Create an array of addresses

        for (uint32 i = 0; i < 10; i++) {
            walletKeys[i] = vm.addr(vm.deriveKey(mnemonic, i));
        }

        return walletKeys;
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
