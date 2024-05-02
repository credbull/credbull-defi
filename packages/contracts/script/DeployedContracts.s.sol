//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { console2 } from "forge-std/console2.sol";

/// @author ian lucas
/// @title Helper to find previously deployed contracts.  For example, within a supabase db export.
contract DeployedContracts is Script {
    string private EMPTY_STRING = "";

    using stdJson for string;

    /// Logic to determine whether or not to deploy
    /// @return whether to deploy or not
    function isDeployRequired(string memory contractName) public virtual returns (bool) {
        bool shouldDeploy = !isFoundInContractDb(contractName);

        if (!shouldDeploy) {
            console2.log("!!!!! Deployment not required for ", contractName, " !!!!!");
        }

        return shouldDeploy;
    }

    /// Check if the Contract is found
    /// @param json the json with a list of contracts or empty
    /// @param contractName the contractName to find
    /// @return true if the contract is found, or false
    function isFound(string memory json, string memory contractName) public pure returns (bool) {
        bytes memory jsonContract = json.parseRaw(string.concat(".", contractName));

        return jsonContract.length > 0;
    }

    /// Read the contract Address.  will revert if the contract is not found in json.
    /// @param json the json with a list of contracts or empty
    /// @param contractName the contractName to find
    /// @return contract address if found, or revert
    function getContractAddress(string memory json, string memory contractName) public pure returns (address) {
        address contractAddress = json.readAddress(string.concat(".", contractName));

        return contractAddress;
    }

    /// Check if the Contract is found.  Uses the supabase db export.
    /// @param contractName the contractName to find
    /// @return true if the contract is found, or false
    function isFoundInContractDb(string memory contractName) public returns (bool) {
        string memory json = parseDeployedContracts();

        if (bytes(json).length == 0) {
            return false;
        }

        return isFound(json, contractName);
    }

    /// Read the deployed contracts from a supabase db export
    /// @return json with a list of deployed contracts or EMPTY_STRING ("")
    function parseDeployedContracts() internal returns (string memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/output/dbdata.json");

        if (vm.exists(path)) {
            string memory json = vm.readFile(path);

            return json;
        }

        return EMPTY_STRING;
    }
}
