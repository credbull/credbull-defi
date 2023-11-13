// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import {INetworkConfig, NetworkConfig} from "../../script/utils/NetworkConfig.s.sol";
import {LocalNetworkConfig} from "../../script/utils/LocalNetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ChainUtil} from "../../script/utils/ChainUtil.sol";

import { console } from "forge-std/console.sol";


contract NetworkConfigTest is Test {
    address private contractOwnerAddr;

    function testCreateLocalNetworkConfig() public {
        address randOwnerAddress = address(4902385); // address can be anything

        INetworkConfig networkConfig = new LocalNetworkConfig(randOwnerAddress, false);

        assertNotEq(address(networkConfig.getUSDC()), address(0)); // zero address would mean not created
    }

}
