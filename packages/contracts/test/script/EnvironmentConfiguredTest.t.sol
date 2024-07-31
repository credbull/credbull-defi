// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { stdToml } from "forge-std/StdToml.sol";

import { Configured } from "@script/Configured.s.sol";

abstract contract EnvironmentConfiguredTest is Test, Configured {
    using stdToml for string;

    function test_Configured_LoadsTestEnvironment() external {
        assertTrue(config().readBool(".test.is_correct_config"));
    }
}

contract OverrideEnvironmentConfiguredTest is EnvironmentConfiguredTest {
    function environment() internal pure override returns (string memory) {
        return "test";
    }
}

contract SetEnvironmentConfiguredTest is EnvironmentConfiguredTest {
    constructor() {
        loadEnvironment("test");
    }
}
