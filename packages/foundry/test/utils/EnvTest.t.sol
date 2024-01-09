// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";

import { console } from "forge-std/console.sol";

contract EnvTest is Test {
    function testGetAddressFromEnv() public {
        string memory key = "SOME_ENVIRONMENT_KEY";
        address valueAsAddr = address(9823095); // any value
        string memory value = vm.toString(valueAsAddr);

        vm.setEnv(key, value); // set the value
        address envAddress = vm.envAddress(key);
        assertEq(valueAsAddr, envAddress);

        vm.expectRevert();
        vm.envAddress("A_KEY_NOT_IN_ENV");
    }

    function testGetAddressFromEnvOrDefault() public {
        string memory keyNotInEnv = "ANOTHER_KEY_NOT_IN_ENV";
        address defaultAddress = address(4354063); // any value

        address envAddress = vm.envOr(keyNotInEnv, defaultAddress);

        assertEq(defaultAddress, envAddress);
    }
}
