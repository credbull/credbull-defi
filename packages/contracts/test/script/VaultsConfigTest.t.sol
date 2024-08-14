// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { VaultsConfig } from "@script/TomlConfig.s.sol";

contract VaultsConfigTest is Test, VaultsConfig {
    string private constant CONFIG = "[deployment.vaults.address]\n"
        'owner = "0x1111111111111111111111111111111111111111"\n'
        'operator = "0x2222222222222222222222222222222222222222"\n'
        'custodian = "0x3333333333333333333333333333333333333333"\n';

    address private constant EXPECTED_OWNER = 0x1111111111111111111111111111111111111111;
    address private constant EXPECTED_OPERATOR = 0x2222222222222222222222222222222222222222;
    address private constant EXPECTED_CUSTODIAN = 0x3333333333333333333333333333333333333333;

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }

    function test_VaultsConfig_OwnerAddress() public {
        assertEq(EXPECTED_OWNER, owner(), "Unexpected Owner Address");
    }

    function test_VaultsConfig_OperatorAddress() public {
        assertEq(EXPECTED_OPERATOR, operator(), "Unexpected Operator Address");
    }

    function test_VaultsConfig_CustodianAddress() public {
        assertEq(EXPECTED_CUSTODIAN, custodian(), "Unexpected Custodian Address");
    }
}

contract AbsentVaultsConfigTest is Test, VaultsConfig {
    string private constant CONFIG =
        "[deployment.vaults.address]\n" 'treasury = "0x1111111111111111111111111111111111111111"\n';

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }

    function testFail_VaultsConfig_RevertWhenOwnerAddressAbsent() public {
        owner();
    }

    function test_VaultsConfig_ExactRevertWhenOwnerAddressAbsent() public {
        vm.expectRevert(abi.encodeWithSelector(ConfigurationNotFound.selector, CONFIG_KEY_ADDRESS_OWNER));
        owner();
    }

    function testFail_VaultsConfig_RevertWhenOperatorAddressAbsent() public {
        operator();
    }

    function test_VaultsConfig_ExactRevertsWhenOperatorAddressAbsent() public {
        vm.expectRevert(abi.encodeWithSelector(ConfigurationNotFound.selector, CONFIG_KEY_ADDRESS_OPERATOR));
        operator();
    }

    function testFail_VaultsConfig_RevertWhenCustodianAddressAbsent() public {
        custodian();
    }

    function test_VaultsConfig_ExactRevertsWhenCustodianAddressAbsent() public {
        vm.expectRevert(abi.encodeWithSelector(ConfigurationNotFound.selector, CONFIG_KEY_ADDRESS_CUSTODIAN));
        custodian();
    }
}
