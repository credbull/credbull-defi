//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

/// @author ian lucas
/// @title Deploy only if a Condition is met
abstract contract ConditionalDeploy is Script {
    string public contractName;
    DeployedContracts private deployedContract;

    constructor(string memory _contractName) {
        contractName = _contractName;

        deployedContract = new DeployedContracts();
    }

    /// Deploy only when a condition is met
    /// @return the deployed contract's address
    function deployIfNeeded() public returns (address) {
        if (shouldDeploy()) {
            return deployAlways();
        } else {
            console2.log("!!!!! Deployment skipped for", contractName, "!!!!!");

            return address(0); // deployment skipped, zero address
        }
    }

    /// Deploys always (ignores the condition)
    /// @return the deployed contract's address
    function deployAlways() public virtual returns (address);

    /// Logic to determine whether or not to deploy
    /// @return whether to deploy or not
    function shouldDeploy() public virtual returns (bool) {
        return !deployedContract.isFoundInContractDb(contractName);
    }
}
