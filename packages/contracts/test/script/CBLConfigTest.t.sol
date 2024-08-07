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

contract AbsentCBLConfigTest is Test, CBLConfig {
    string private constant CONFIG =
        "[deployment.cbl]\n" "[deployment.cbl.address]\n" 'treasury = "0x4444444444444444444444444444444444444444"\n';

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }

    function testFail_CBLConfig_RevertWhenOwnerAddressAbsent() public {
        owner();
    }

    function test_CBLConfig_ExactRevertWhenOwnerAddressAbsent() public {
        vm.expectRevert(abi.encodeWithSelector(ConfigurationNotFound.selector, CONFIG_KEY_ADDRESS_OWNER));
        owner();
    }

    function testFail_CBLConfig_RevertWhenMinterAddressAbsent() public {
        minter();
    }

    function test_CBLConfig_ExactRevertWhenMinterAddressAbsent() public {
        vm.expectRevert(abi.encodeWithSelector(ConfigurationNotFound.selector, CONFIG_KEY_ADDRESS_MINTER));
        minter();
    }

    function testFail_CBLConfig_RevertWhenMaxSupplyAbsent() public {
        maxSupply();
    }

    function test_CBLConfig_ExactRevertWhenMaxSupplyAbsent() public {
        vm.expectRevert(abi.encodeWithSelector(ConfigurationNotFound.selector, CONFIG_KEY_MAX_SUPPLY));
        maxSupply();
    }
}
