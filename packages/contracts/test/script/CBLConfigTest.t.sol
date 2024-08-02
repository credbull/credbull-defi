// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { CBLConfig } from "@script/TomlConfig.s.sol";

contract CBLConfigTest is Test, CBLConfig {
    string private constant CONFIG = "[deployment.cbl]\n" "max_supply = 1_234_567_890\n"
        "[deployment.cbl.address]\n" 'owner = "0x4444444444444444444444444444444444444444"\n'
        'minter = "0x5555555555555555555555555555555555555555"\n';

    address private constant EXPECTED_OWNER = 0x4444444444444444444444444444444444444444;
    address private constant EXPECTED_MINTER = 0x5555555555555555555555555555555555555555;
    uint256 private constant EXPECTED_MAX_SUPPLY = 1_234_567_890 * PRECISION;

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }

    function test_CBLConfig_OwnerAddress() public {
        assertEq(EXPECTED_OWNER, owner(), "Unexpected Owner Address");
    }

    function test_CBLConfig_MinterAddress() public {
        assertEq(EXPECTED_MINTER, minter(), "Unexpected Minter Address");
    }

    function test_CBLConfig_MaxSupply() public {
        assertEq(EXPECTED_MAX_SUPPLY, maxSupply(), "Unexpected Max Supply Amount");
    }
}
