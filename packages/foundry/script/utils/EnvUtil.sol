// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

contract EnvUtil is Script {
    function getAddressFromEnvironment(string memory envKey) public view returns (address) {
        string memory value = vm.envString(envKey);

        address valueAddress = vm.parseAddress(value);

        return valueAddress;
    }
}
