// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { VaultsSupportConfigured } from "@script/Configured.s.sol";

contract VaultsSupportConfiguredTest is Test, VaultsSupportConfigured {
    address private constant EXPECTED_OWNER = 0x1111111111111111111111111111111111111111;
    address private constant EXPECTED_OPERATOR = 0x2222222222222222222222222222222222222222;
    address private constant EXPECTED_CUSTODIAN = 0x3333333333333333333333333333333333333333;

    function environment() internal pure override returns (string memory) {
        return "test";
    }

    function test_VaultsSupportConfigured_IsDeploySupportFlag() public {
        assertFalse(isDeploySupport(), "Unexpected Is Deploy Support Flag");
    }

    // NOTE (JL,2024-07-31): The following tests kept for regression assurance.
    function test_VaultsSupportConfigured_OwnerAddress() public {
        assertEq(EXPECTED_OWNER, owner(), "Unexpected Owner Address");
    }

    function test_VaultsSupportConfigured_OperatorAddress() public {
        assertEq(EXPECTED_OPERATOR, operator(), "Unexpected Operator Address");
    }

    function test_VaultsSupportConfigured_CustodianAddress() public {
        assertEq(EXPECTED_CUSTODIAN, custodian(), "Unexpected Custodian Address");
    }
}
