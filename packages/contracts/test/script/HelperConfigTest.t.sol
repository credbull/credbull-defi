//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperConfig, NetworkConfig, FactoryParams } from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test, HelperConfig {
    constructor() HelperConfig(true) { }

    function test__HelperConfig__NetworkConfig() public {
        HelperConfig helperConfig = new HelperConfig(false);

        NetworkConfig memory config = helperConfig.getNetworkConfig();
        FactoryParams memory factoryParams = config.factoryParams;

        assertNotEq(address(0), factoryParams.operator);
    }

    function test__HelperConfig_WalletsFromMnemonic() public {
        string memory mnemonic = "region welcome ankle law galaxy nasty wisdom iron hazard lounge owner crowd";

        address[] memory walletKeys = deriveKeys(mnemonic);

        assertEq(vm.addr(vm.deriveKey(mnemonic, 0)), walletKeys[0], "key 0 mismatch");
        assertEq(vm.addr(vm.deriveKey(mnemonic, 1)), walletKeys[1], "key 1 mismatch");
        assertEq(vm.addr(vm.deriveKey(mnemonic, 9)), walletKeys[9], "key 9 mismatch");
    }

    function test__HelperConfig_createFactoryParamsFromAnvilMnemonic() public {
        string memory mnemonic = getAnvilMnemonic();
        address[] memory walletKeys = deriveKeys(mnemonic);

        assertNotEq(address(0), walletKeys[0], "key 0 not set");
        assertNotEq(address(0), walletKeys[1], "key 1 not set");

        NetworkConfig memory config = getNetworkConfig();
        FactoryParams memory factoryParams = config.factoryParams;

        assertEq(factoryParams.owner, walletKeys[0]);
        assertEq(factoryParams.operator, walletKeys[1]);
    }
}
