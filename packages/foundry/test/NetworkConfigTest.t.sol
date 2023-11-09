// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";
import { DeployCredbullVault } from "../script/DeployCredbullVault.s.sol";
import { DeployScript } from "../script/Deploy.s.sol";
import { NetworkConfigFactory, INetworkConfig, Addresses} from "../script/NetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ChainUtil} from "../script/utils/ChainUtil.sol";

contract NetworkConfigTest is Test {
    IERC20 usdcOptimismGoerli = IERC20(Addresses.USDC_OPTIMISM_GOERLI_ADDRESS);

    address contractOwnerAddr;

    function testCreateLocalNetworkConfig() public {
        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(address(4));

        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertNotEq(address(networkConfig.getUSDC()), address(0));
    }
}
