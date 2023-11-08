// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";
import { DeployCredbullVault } from "../script/DeployCredbullVault.s.sol";
import { DeployScript } from "../script/Deploy.s.sol";
import { NetworkConfigFactory, INetworkConfig, Addresses} from "../script/NetworkConfig.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract NetworkConfigTest is Test {
    IERC20 optimistGoerliTetherToken = IERC20(Addresses.TETHER_OPTIMISM_GOERLI_ADDRESS);

    address contractOwnerAddr;

    function testCreateOptimismGoerliNetworkConfig() public {
        vm.chainId(420);

        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(address(0));
        
        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertEq(address(networkConfig.getTetherToken()), address(optimistGoerliTetherToken));
        assertEq(address(networkConfig.getCredbullVaultAsset()), address(optimistGoerliTetherToken));
    }

    function testCreateLocalNetworkConfig() public {
        vm.chainId(31337);

        NetworkConfigFactory networkConfigFactory = new NetworkConfigFactory(address(4));

        // new method on Factory to return NetworkConfig for Optimism
        INetworkConfig networkConfig = networkConfigFactory.getNetworkConfig();

        assertNotEq(address(networkConfig.getTetherToken()), address(0));
    }
}
