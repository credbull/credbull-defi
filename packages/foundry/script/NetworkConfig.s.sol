// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockTetherToken} from "../test/mocks/MockTetherToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/Test.sol";

interface INetworkConfig {
    function getTetherToken() external view returns (IERC20);

    function getCredbullVaultAsset() external view returns (IERC20);
}

contract DeployNetworkConfig is Script {
    uint256 public constant BASE_TOKEN_AMOUNT = 50000;

    INetworkConfig public activeNetworkConfig;

    // For full chainLists see: https://chainlist.org/
    constructor() {
        activeNetworkConfig = getOrCreateLocalConfig();
    }

    function getOrCreateLocalConfig() public returns (INetworkConfig) {
        if (address(activeNetworkConfig) != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockTetherToken mockTetherToken = new MockTetherToken(
            BASE_TOKEN_AMOUNT
        );

        console.logString(string.concat("MockTetherToken deployed at: ", vm.toString(address(mockTetherToken))));

        vm.stopBroadcast();

        INetworkConfig networkConfig = new NetworkConfig(
            mockTetherToken,
            mockTetherToken
        );

        return networkConfig;
    }
}

contract NetworkConfig is INetworkConfig {
    IERC20 public tetherToken;
    IERC20 public credbullVaultAsset;

    constructor(IERC20 _tetherToken, IERC20 _credbullVaultAsset) {
        tetherToken = _tetherToken;
        credbullVaultAsset = _credbullVaultAsset;
    }

    function getTetherToken() public view override returns (IERC20) {
        return tetherToken;
    }

    function getCredbullVaultAsset() public view override returns (IERC20) {
        return credbullVaultAsset;
    }
}
