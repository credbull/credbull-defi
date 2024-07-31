// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { CBLConfigured } from "@script/Configured.s.sol";

contract CBLConfiguredTest is Test, CBLConfigured {
    address private constant EXPECTED_OWNER = 0x4444444444444444444444444444444444444444;
    address private constant EXPECTED_MINTER = 0x5555555555555555555555555555555555555555;
    uint256 private constant EXPECTED_MAX_SUPPLY = 1_234_567_890 * PRECISION;

    function environment() internal pure override returns (string memory) {
        return "test";
    }

    function test_CBLConfigured_OwnerAddress() public {
        assertEq(EXPECTED_OWNER, owner(), "Unexpected Owner Address");
    }

    function test_CBLConfigured_MinterAddress() public {
        assertEq(EXPECTED_MINTER, minter(), "Unexpected Minter Address");
    }

    function test_CBLConfigured_MaxSupply() public {
        assertEq(EXPECTED_MAX_SUPPLY, maxSupply(), "Unexpected Max Supply Amount");
    }
}
