// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { NetworkConfigFactory, INetworkConfig, Addresses} from "../../script/utils/NetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ChainUtil} from "../../script/utils/ChainUtil.sol";

contract NetworkConfigTest is Test {
    IERC20 usdcOptimismGoerli = IERC20(Addresses.USDC_OPTIMISM_GOERLI_ADDRESS);

    address contractOwnerAddr;

    function testCreateNetworkConfigForLocalChain() public {
        address randOwnerAddress = address(4902385); // address can be anything

        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(randOwnerAddress);
        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertNotEq(address(networkConfig.getUSDC()), address(0)); // zero address would mean not created
    }

    function testCreateNetworkConfigForMockChain() public {
        address randOwnerAddress = address(4902386); // address can be anything

        // first setup a mock/stub chain and it to known chains.
        uint mockChainId = 99238525;
        string memory mockChainAlias = "testChainAlias-99238525";
        Chain memory mockChain = Chain ({name: mockChainAlias, chainId: mockChainId, chainAlias: mockChainAlias, rpcUrl:"http://localhost:7000"});
        ChainUtil chainUtil = new ChainUtil();
        chainUtil.setChainByAlias(mockChainAlias, mockChain);


        // Change NetworkConfigFactory to be mapping for Chain -> NetworkConfig
        // in this case, we want to add the mapping for Network Config Factory
        // TODO: we'll need to go back and fix the local test somehow to do the Deploy and the Mapping.  Maybe by extending NetworkConfigFactory.

        // now try to get the configuration for the mock chain
        // TODO: add this back.  change the chain on the vm - vm.chainId(mockChainId);
        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(randOwnerAddress);
        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertNotEq(address(networkConfig.getUSDC()), address(0)); // zero address would mean not created
    }
}
