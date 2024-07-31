// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { VaultsConfigured } from "@script/Configured.s.sol";

contract NetworkOverrideVaultsConfiguredTest is Test, VaultsConfigured {
    address private constant EXPECTED_OWNER_OVERRIDE = 0x6666666666666666666666666666666666666666;

    function environment() internal pure override returns (string memory) {
        return "test";
    }

    function chain() internal override returns (Chain memory) {
        return getChain("arbitrum_one_sepolia");
    }

    function test_VaultsConfigured_NetworkOverrideOwnerAddress() public {
        assertEq(EXPECTED_OWNER_OVERRIDE, owner(), "Unexpected Network Override Owner Address");
    }
}
