// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { VaultsConfig } from "@script/TomlConfig.s.sol";

contract NetworkOverrideVaultsConfigTest is Test, VaultsConfig {
    string private constant CONFIG = "[deployment.vaults.address]\n"
        'owner = "0x1111111111111111111111111111111111111111"\n'
        'operator = "0x2222222222222222222222222222222222222222"\n'
        'custodian = "0x3333333333333333333333333333333333333333"\n'
        "[network.arbitrum_one_sepolia.deployment.vaults.address]\n"
        'owner = "0x6666666666666666666666666666666666666666"\n';

    address private constant EXPECTED_OWNER_OVERRIDE = 0x6666666666666666666666666666666666666666;

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }

    function chain() internal override returns (Chain memory) {
        return getChain("arbitrum_one_sepolia");
    }

    function test_VaultsConfigured_NetworkOverrideOwnerAddress() public {
        assertEq(EXPECTED_OWNER_OVERRIDE, owner(), "Unexpected Network Override Owner Address");
    }
}
