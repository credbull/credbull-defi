//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullBaseVaultMock } from "../mocks/vaults/CredbullBaseVaultMock.m.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig, FactoryParams, ContractRoles } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { CredbullBaseVault } from "../../src/base/CredbullBaseVault.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { console2 } from "forge-std/console2.sol";

contract HelperConfigTest is Test {
    function test__HelperConfig_createRolesFromMnemonic() public {
        HelperConfig helperConfig = new HelperConfig(true);

        string memory mnemonic = "region welcome ankle law galaxy nasty wisdom iron hazard lounge owner crowd";

        ContractRoles memory contractRoles = helperConfig.createRolesFromMnemonic(mnemonic);

        assertEq(vm.addr(vm.deriveKey(mnemonic, 0)), contractRoles.owner);
        assertEq(vm.addr(vm.deriveKey(mnemonic, 1)), contractRoles.operator);
        assertEq(vm.addr(vm.deriveKey(mnemonic, 2)), contractRoles.additionalRoles[0]);
    }
}
