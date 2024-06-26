//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperConfig, NetworkConfig, FactoryParams } from "@script/HelperConfig.s.sol";

contract HelperConfigTest is Test, HelperConfig {
    constructor() HelperConfig(true) { }

    function test__HelperConfig__NetworkConfig() public {
        HelperConfig helperConfig = new HelperConfig(false);

        NetworkConfig memory config = helperConfig.getNetworkConfig();
        FactoryParams memory factoryParams = config.factoryParams;

        assertNotEq(address(0), factoryParams.operator);
    }
}
