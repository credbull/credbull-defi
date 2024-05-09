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

    function test__TomlTest_SeparateToml_ReadValue() public view {
        string memory toml = vm.readFile(path);

        // read a value directly
        assertEq("localChain1", toml.readString(".contracts.chainName"));
    }

    function test__TomlTest_EnvSpecificTables_ReadValue() public view {
        string memory toml = vm.readFile(path);

        // read a value directly
        assertEq("localChain2", toml.readString(".local.contracts.chainName"));
    }


    function test__TomlTest_ReadTableKeys() public view {

        logKeyAndVals(".contracts"); // 1 - separate key file

        logKeyAndVals(".local.contracts"); // 2 - separate env tables
        logKeyAndVals(".local.api"); // 2 - separate env tables

        // more info on syntax here: https://crates.io/crates/jsonpath-rust
        logKeyAndVals(".env[0].contracts"); // 3 - array of env tables
        logKeyAndVals(".env[1].contracts"); // 3 - array of env tables
    }


    function logKeyAndVals(string memory tomlPath) public view {
        string memory toml = vm.readFile(path);
        string [] memory contractKeys = vm.parseTomlKeys(toml, tomlPath);

        console.log('========== logging key/vals in path: "', tomlPath, '"');

        for (uint256 i = 0; i < contractKeys.length; i++) {
            string memory key = contractKeys[i];
            string memory val = toml.readString(string.concat(tomlPath, ".", key));

            console.log(string.concat(vm.toString(i), ": ", key, "=", val));
        }
    }

/*
//     Example for binding to Struct below.  Risky, don't use.  Maps using alphabetical order!
//     From https://book.getfoundry.sh/cheatcodes/parse-toml
//     What matters is the alphabetical order. As the JSON object is an unordered ... but the tuple is an ordered ... we had to somehow give order to the JSON.
//     The easiest way was to order the keys by alphabetical order.
*/
    struct Contracts {
        string chainName;
        uint256 deployerPrivateKey;
        address operatorAddress;
        address ownerAddress;
    }

    function test__TomlTest_Flat_ReadTableAsStruct() public view {
        string memory toml = vm.readFile(path);
        bytes memory contractTable = toml.parseRaw(".contracts");

        Contracts memory contracts = abi.decode(contractTable, (Contracts));

        assertEq(toml.readString(".contracts.chainName"), contracts.chainName);
        assertEq(toml.readUint(".contracts.deployerPrivateKey"), contracts.deployerPrivateKey);
        assertEq(toml.readAddress(".contracts.operatorAddress"), contracts.operatorAddress);
        assertEq(toml.readAddress(".contracts.ownerAddress"), contracts.ownerAddress);
    }

}
