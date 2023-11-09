// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";
import { DeployCredbullVault } from "../script/DeployCredbullVault.s.sol";
import { DeployScript } from "../script/Deploy.s.sol";
import { NetworkConfigFactory, INetworkConfig, Addresses} from "../script/NetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ChainsUtil} from "../script/utils/ChainsUtil.sol";

contract NetworkConfigTest is Test {
    IERC20 usdcOptimismGoerli = IERC20(Addresses.USDC_OPTIMISM_GOERLI_ADDRESS);

    address contractOwnerAddr;

    function testCreateLocalNetworkConfig() public {
        Chain memory chain = new ChainsUtil().getAnvilChain(); // explicitly set the local network
        vm.chainId(chain.chainId);

        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(address(4));

        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertNotEq(address(networkConfig.getUSDC()), address(0));
    }

    function testCreateOptimismGoerliNetworkConfig() public {
        Chain memory chain = new ChainsUtil().getOptimismGoerliChain();
        vm.chainId(chain.chainId);

        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(address(0));
        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertEq(address(networkConfig.getUSDC()), address(usdcOptimismGoerli));
        assertEq(address(networkConfig.getCredbullVaultAsset()), address(usdcOptimismGoerli));
    }
}
