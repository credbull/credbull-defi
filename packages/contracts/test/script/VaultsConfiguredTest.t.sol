// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { VaultsConfigured } from "@script/Configured.s.sol";

contract VaultsConfiguredTest is Test, VaultsConfigured {
    address private constant EXPECTED_OWNER = 0x1111111111111111111111111111111111111111;
    address private constant EXPECTED_OPERATOR = 0x2222222222222222222222222222222222222222;
    address private constant EXPECTED_CUSTODIAN = 0x3333333333333333333333333333333333333333;

    function environment() internal pure override returns (string memory) {
        return "test";
    }

    function test_VaultsConfigured_OwnerAddress() public {
        assertEq(EXPECTED_OWNER, owner(), "Unexpected Owner Address");
    }

    function test_VaultsConfigured_OperatorAddress() public {
        assertEq(EXPECTED_OPERATOR, operator(), "Unexpected Operator Address");
    }

    function test_VaultsConfigured_CustodianAddress() public {
        assertEq(EXPECTED_CUSTODIAN, custodian(), "Unexpected Custodian Address");
    }
}
