// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { INetworkConfig } from "./NetworkConfig.s.sol";
import { DeployMockStablecoin } from "../mocks/DeployMockStablecoin.s.sol";
import { DeployMockStablecoinFaucet } from "../mocks/DeployMockStablecoinFaucet.s.sol";
import { MockStablecoin } from "../../test/mocks/MockStablecoin.sol";

/**
* Represents a Local Network for scripts and testing purposes.
*
* NB - this is not a "global" Singleton.  Nothing  prevents multiple LocalNetworkConfigs from being created,
* each at different addresses and with different associated stablecoins.
*/
contract LocalNetworkConfig is INetworkConfig {
    IERC20 mockStablecoin;

    bool private initialized;

    constructor(address contractOwnerAddress, bool hasFaucet) {
        mockStablecoin = initializeNetworkConfig(contractOwnerAddress, hasFaucet);
    }

    function initializeNetworkConfig(address contractOwnerAddress, bool hasFaucet) internal returns (IERC20) {
        require(!initialized, "LocalNetworkConfig already initialized.");
        initialized = true;

        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();
        MockStablecoin _mockStablecoin = deployStablecoin.run(contractOwnerAddress);

        if(hasFaucet) {
            DeployMockStablecoinFaucet deployFaucet = new DeployMockStablecoinFaucet();
            deployFaucet.run(contractOwnerAddress, _mockStablecoin);
        }

        return _mockStablecoin;
    }

    function getUSDC() public view override returns (IERC20) {
        return mockStablecoin;
    }

    function getCredbullVaultAsset() public view override returns (IERC20) {
        return mockStablecoin;
    }
}
