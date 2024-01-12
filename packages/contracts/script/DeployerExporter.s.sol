//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Console.sol";

contract Exporter is Script {
    struct Deployment {
        string name;
        address addr;
    }

    string root;
    string path;
    Deployment[] public deployments;

    function exportDeployments(string memory contractName, address contractAddress) internal {
        // fetch already existing contracts
        root = vm.projectRoot();
        path = string.concat(root, "/deployments/");
        string memory chainIdStr = vm.toString(block.chainid);
        path = string.concat(path, string.concat(chainIdStr, ".json"));

        string memory jsonWrite;

        jsonWrite = vm.serializeString(jsonWrite, contractName, vm.toString(contractAddress));
        vm.writeJson(jsonWrite, path);
    }
}
