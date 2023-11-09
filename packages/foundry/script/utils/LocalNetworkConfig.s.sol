// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {INetworkConfig} from "./NetworkConfig.s.sol";
import { DeployMockStablecoin } from "../mocks/DeployMockStablecoin.s.sol";
import { MockStablecoin } from "../../test/mocks/MockStablecoin.sol";

contract LocalNetworkConfig is INetworkConfig {
    IERC20 mockStablecoin;

    constructor(address contractOwnerAddress) {
        mockStablecoin = createStablecoin(contractOwnerAddress);
    }

    function createStablecoin(address contractOwnerAddress) internal returns (IERC20) {
        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();

        MockStablecoin _mockStablecoin = deployStablecoin.run(contractOwnerAddress);

        return _mockStablecoin;
    }

    function getUSDC() public view override returns (IERC20) {
        return mockStablecoin;
    }

    function getCredbullVaultAsset() public view override returns (IERC20) {
        return mockStablecoin;
    }
}
