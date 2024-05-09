// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { stdToml } from "forge-std/StdToml.sol";

contract TomlTest is Test {
    using stdToml for string;

    string root;
    string path;

    function setUp() public {
        root = vm.projectRoot();
        path = string.concat(root, "/test/fixtures/spike.toml");
    }

    function test_readValue() public view {
        string memory toml = vm.readFile(path);

        // read a value directly
        assertEq("FixedVault", toml.readString(".contracts.vaultName"));
    }

    function test_readTableKeys() public view {
        string memory toml = vm.readFile(path);
        string [] memory contractKeys = vm.parseTomlKeys(toml, ".contracts");

        for (uint256 i = 0; i < contractKeys.length; i++) {
            string memory key = contractKeys[i];
            string memory val = toml.readString(string.concat(".contracts.", key));

            console.log(string.concat(vm.toString(i), ": ", key, "=", val));
        }

    }

/*
// https://book.getfoundry.sh/cheatcodes/parse-toml
//     Represents the Contracts Table in toml file.  Recommend not to use this approach.  Binding is based on alphabetical order only!
//
//     From https://book.getfoundry.sh/cheatcodes/parse-toml
//     What matters is the alphabetical order. As the JSON object is an unordered ... but the tuple is an ordered ... we had to somehow give order to the JSON.
//     The easiest way was to order the keys by alphabetical order.
*/
    struct Contracts {
        uint256 deployerPrivateKey;
        address operatorAddress;
        address ownerAddress;
        string vaultName;
    }

    function test_ReadTableAsStruct() public view {
        string memory toml = vm.readFile(path);
        bytes memory contractTable = toml.parseRaw(".contracts");

        Contracts memory contracts = abi.decode(contractTable, (Contracts));

        assertEq(toml.readUint(".contracts.deployerPrivateKey"), contracts.deployerPrivateKey);
        assertEq(toml.readAddress(".contracts.operatorAddress"), contracts.operatorAddress);
        assertEq(toml.readAddress(".contracts.ownerAddress"), contracts.ownerAddress);
        assertEq(toml.readString(".contracts.vaultName"), contracts.vaultName);
    }

}
