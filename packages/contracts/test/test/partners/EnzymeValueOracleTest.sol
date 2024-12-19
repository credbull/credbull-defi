// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

contract EnzymeValueOracleTest is Test {
    string private constant MESSAGE_STR = "credbull testing - 20241209";

    function test__EnzymeValueOracle__Identity() public pure {
        bytes memory msgEncoded = abi.encode(MESSAGE_STR); // this will be variable

        string memory decoded = abi.decode(msgEncoded, (string));

        assertEq(MESSAGE_STR, decoded, "encode and decode should return message");
    }

    function test__EnzymeValueOracle__AsBytes32() public pure {
        bytes32 msgBytes32 = bytes32(abi.encodePacked(MESSAGE_STR));

        console2.logBytes32(msgBytes32); // equals 0x6372656462756c6c2074657374696e67202d2032303234313230390000000000

        assertEq(vm.toString(msgBytes32), "0x6372656462756c6c2074657374696e67202d2032303234313230390000000000");
    }
}
