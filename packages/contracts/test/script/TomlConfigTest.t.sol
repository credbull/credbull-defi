// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { stdToml } from "forge-std/StdToml.sol";

import { TomlConfig } from "@script/TomlConfig.s.sol";

abstract contract TomlConfigTest is Test, TomlConfig {
    using stdToml for string;

    string internal constant EXPECTED_TESTNET = "https://kyvvhlnmoqibdihqrlmc.supabase.co";

    function testValue() internal returns (string memory) {
        return config().readString(".services.supabase.url");
    }
}

contract OverrideEnvironmentTomlConfigTest is TomlConfigTest {
    function environment() internal pure override returns (string memory) {
        return "testnet";
    }

    function test_OverrideEnvironmentTomlConfigTest_LoadsExpectedEnvironment() external {
        assertEq(EXPECTED_TESTNET, testValue(), "Unexpected Test Value Loaded.");
    }
}

contract SetEnvironmentTomlConfigTest is TomlConfigTest {
    constructor() {
        loadEnvironment("testnet");
    }

    function test_SetEnvironmentTomlConfigTest_LoadsExpectedEnvironment() external {
        assertEq(EXPECTED_TESTNET, testValue(), "Unexpected Test Value Loaded.");
    }
}

contract LoadCustomTomlConfigTest is TomlConfigTest {
    using stdToml for string;

    string private constant CONFIG = "[loads.totally]\ncustom_config = true\n";

    function loadConfiguration(string memory _environment) internal view override returns (string memory) {
        assertEq(vm.envString("ENVIRONMENT"), _environment, "Unexpected Environment specifier.");
        return CONFIG;
    }

    function test_LoadCustomTomlConfigTest_LoadsExpectedConfig() external {
        assertEq(CONFIG, config(), "Unexpected Test Value Loaded.");
        assertTrue(config().readBool(".loads.totally.custom_config"), "Incorrect configuration value.");
    }
}
