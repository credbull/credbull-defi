// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { VaultsSupportConfig } from "@script/TomlConfig.s.sol";

contract VaultsSupportConfigTest is Test, VaultsSupportConfig {
    string private constant CONFIG = "[deployment.vaults.address]\n"
        'owner = "0x1111111111111111111111111111111111111111"\n'
        'operator = "0x2222222222222222222222222222222222222222"\n'
        'custodian = "0x3333333333333333333333333333333333333333"\n' "[deployment.vaults_support]\n" "deploy = false\n";

    address private constant EXPECTED_OWNER = 0x1111111111111111111111111111111111111111;
    address private constant EXPECTED_OPERATOR = 0x2222222222222222222222222222222222222222;
    address private constant EXPECTED_CUSTODIAN = 0x3333333333333333333333333333333333333333;

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }

    function test_VaultsSupportConfig_IsDeploySupportFlag() public {
        assertFalse(isDeploySupport(), "Unexpected Is Deploy Support Flag");
    }

    // NOTE (JL,2024-07-31): The following tests kept for regression assurance.
    function test_VaultsSupportConfig_OwnerAddress() public {
        assertEq(EXPECTED_OWNER, owner(), "Unexpected Owner Address");
    }

    function test_VaultsSupportConfig_OperatorAddress() public {
        assertEq(EXPECTED_OPERATOR, operator(), "Unexpected Operator Address");
    }

    function test_VaultsSupportConfig_CustodianAddress() public {
        assertEq(EXPECTED_CUSTODIAN, custodian(), "Unexpected Custodian Address");
    }
}
