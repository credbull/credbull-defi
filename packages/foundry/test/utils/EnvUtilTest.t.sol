// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";

import { console } from "forge-std/console.sol";
import {EnvUtil} from "../../script/utils/EnvUtil.sol";

contract EnvUtilTest is Test {

    function testFetchConfigFromEnvironment() public {
        string memory key = "RANDOM_ENVIRONMENT_KEY";
        address valueAsAddr = address(9823095); // any value
        string memory value = vm.toString(valueAsAddr);

        vm.setEnv(key, value); // set the value
        EnvUtil envUtil = new EnvUtil();
        address envAddress = envUtil.getAddressFromEnvironment(key);

        assertEq(valueAsAddr, envAddress);
    }
}
