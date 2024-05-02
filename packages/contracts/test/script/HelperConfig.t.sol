//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperConfig, ContractRoles } from "../../script/HelperConfig.s.sol";

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
