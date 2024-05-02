//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { DeployedContracts } from "../../script/DeployedContracts.s.sol";

contract DeployedContractsTest is Test {
    function test__DeployedContracts() public {
        string memory contractFoo = "ContractFoo";
        address contractFooAddr = makeAddr("keyFoo");

        string memory contractBar = "ContractBar";
        address contractBarAddr = makeAddr("keyBar");

        string memory jsonKey = "keyForJson";
        vm.serializeAddress(jsonKey, contractFoo, contractFooAddr);
        string memory contractsJson = vm.serializeAddress(jsonKey, contractBar, contractBarAddr);

        DeployedContracts deployedContracts = new DeployedContracts();

        // check isFound - returns boolean
        assertTrue(deployedContracts.isFound(contractsJson, contractFoo));
        assertTrue(deployedContracts.isFound(contractsJson, contractBar));
        assertFalse(deployedContracts.isFound(contractsJson, "SomeContract"));

        // check getContract addresses
        assertEq(contractFooAddr, deployedContracts.getContractAddress(contractsJson, contractFoo));
        assertEq(contractBarAddr, deployedContracts.getContractAddress(contractsJson, contractBar));

        // revert if not found
        vm.expectRevert();
        deployedContracts.getContractAddress(contractsJson, "AnotherContract");
    }

    function test__DeployedContracts__NotFoundIfEmptyJson() public {
        DeployedContracts deployedContracts = new DeployedContracts();

        assertFalse(deployedContracts.isFound("{}", "SomeContract"));

        // revert if invalid json
        vm.expectRevert();
        assertFalse(deployedContracts.isFound("", "AnotherContract"));
    }

    function test__DeployedContracts__IsDeployRequired() public {
        string memory contractName = "ZZContract";

        DeployedContracts deployedContracts = new DeployedContracts();

        assertFalse(deployedContracts.isFoundInContractDb(contractName));
        assertTrue(deployedContracts.isDeployRequired(contractName));
    }
}
