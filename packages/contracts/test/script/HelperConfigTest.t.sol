//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";

import { HelperConfig, NetworkConfig, ContractRoles, FactoryParams } from "../../script/HelperConfig.s.sol";

contract HelperConfigTest is Test {
    function test__HelperConfig_createRolesFromMnemonic() public {
        HelperConfig helperConfig = new HelperConfig(true);

        string memory mnemonic = "region welcome ankle law galaxy nasty wisdom iron hazard lounge owner crowd";

        ContractRoles memory contractRoles = helperConfig.createRolesFromMnemonic(mnemonic);

        assertEq(vm.addr(vm.deriveKey(mnemonic, 0)), contractRoles.owner);
        assertEq(vm.addr(vm.deriveKey(mnemonic, 1)), contractRoles.operator);
        assertEq(vm.addr(vm.deriveKey(mnemonic, 2)), contractRoles.additionalRoles[0]);
    }

    function test__HelperConfig__AnvilConfig() public {
        HelperConfig helperConfig = new HelperConfig(true);
        NetworkConfig memory config;
        ICredbull.VaultParams memory vaultParams;
        (config, vaultParams) = helperConfig.getAnvilEthConfig();

        assertNotEq(address(0), vaultParams.operator);

        FactoryParams memory factoryParams = config.factoryParams;
        assertNotEq(address(0), factoryParams.operator);
    }

    function test__HelperConfig__SepoliaConfig() public {
        HelperConfig helperConfig = new HelperConfig(false);

        NetworkConfig memory config = helperConfig.getNetworkConfig();

        FactoryParams memory factoryParams = config.factoryParams;
        assertNotEq(address(0), factoryParams.operator);
    }
}
