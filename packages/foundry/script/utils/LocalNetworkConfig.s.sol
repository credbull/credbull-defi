// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ChainUtil} from "./ChainUtil.sol";
import { NetworkConfigs, INetworkConfig} from "./NetworkConfig.s.sol";

import { DeployMockStablecoin } from "../mocks/DeployMockStablecoin.s.sol";
import { MockStablecoin } from "../../test/mocks/MockStablecoin.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";

contract LocalNetworkConfigs is NetworkConfigs {
    ChainUtil private chainUtil;

    constructor(address contractOwnerAddress) {
        chainUtil = new ChainUtil();

        INetworkConfig localNetworkConfig = createLocalNetwork(contractOwnerAddress);
        registerNetworkConfig(chainUtil.getAnvilChain(), localNetworkConfig);
    }

    function createLocalNetwork(address contractOwnerAddress) internal returns (INetworkConfig) {
        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();
        MockStablecoin mockStablecoin = deployStablecoin.run(contractOwnerAddress);

        INetworkConfig networkConfig = new NetworkConfig(mockStablecoin, mockStablecoin);

        return networkConfig;
    }
}
