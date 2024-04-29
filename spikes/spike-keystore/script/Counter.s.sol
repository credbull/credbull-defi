// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/Counter.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        Counter counter = new Counter();

        console.logString(
            string.concat(
                "Counter deployed at: ", vm.toString(address(counter))
            )
        );

        vm.stopBroadcast();

    }
}
