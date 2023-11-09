// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import {NetworkConfigs, INetworkConfig, NetworkConfig} from "../../script/utils/NetworkConfig.s.sol";
import {LocalNetworkConfigs} from "../../script/utils/LocalNetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ChainUtil} from "../../script/utils/ChainUtil.sol";

import { console } from "forge-std/console.sol";


contract NetworkConfigTest is Test {
    address contractOwnerAddr;

    function testCreateNetworkConfigForLocalChain() public {
        address randOwnerAddress = address(4902385); // address can be anything

        NetworkConfigs networkConfigs = new LocalNetworkConfigs(randOwnerAddress);
        INetworkConfig networkConfig = networkConfigs.getNetworkConfig();

        assertNotEq(address(networkConfig.getUSDC()), address(0)); // zero address would mean not created
    }

    function testCreateNetworkConfigForMockChain() public {
        // first setup a mock/stub chain and it to known chains.
        uint mockChainId = 99238525;
        string memory mockChainAlias = "testChainAlias-99238525";
        Chain memory mockChain = Chain ({name: mockChainAlias, chainId: mockChainId, chainAlias: mockChainAlias, rpcUrl:"http://localhost:7000"});

        // create a mockUSDC and network config for our chain
        IERC20 mockUSDC = IERC20(address(9646464)); // address can be anything
        INetworkConfig mockChainConfig = new NetworkConfig(mockUSDC, mockUSDC);

        // Change NetworkConfigFactory to be mapping for Chain -> NetworkConfig
        NetworkConfigs networkConfigs = new NetworkConfigs();
        networkConfigs.registerNetworkConfig(mockChain, mockChainConfig);

        // fetch the network config by chain and make sure it is the one we expect
        assertEq(address(mockChainConfig.getUSDC()), address(networkConfigs.getNetworkConfigByChain(mockChain).getUSDC()));

        // fetch the "current" network config and make sure it is the one we expect
        vm.chainId(mockChainId);
        assertEq(address(mockChainConfig.getUSDC()), address(networkConfigs.getNetworkConfig().getUSDC()));

    }

    function testRevertIfNetworkConfigNotRegistered() public {
        uint mockChainId = 89235098; // some random chainId

        vm.chainId(mockChainId);
        NetworkConfigs networkConfigs = new NetworkConfigs();

        vm.expectRevert();
        networkConfigs.getNetworkConfig();
    }

    function testFetchConfigFromEnvironment() public {
        string memory key = "RANDOM_ENVIRONMENT_KEY";
        address valueAsAddr = address(9823095); // any value
        string memory value = vm.toString(valueAsAddr);

        vm.setEnv(key, value); // set the value
        address envAddress = new NetworkConfigs().getAddressFromEnvironment(key);

        assertEq(valueAsAddr, envAddress);
    }
}
