//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "./DeployHelpers.s.sol";

import { TimelockInterestVault } from "@credbull/contracts/fixed/TimelockInterestVault.sol";
import { SimpleToken } from "@credbull/contracts/token/SimpleToken.sol";

contract DeployScript is ScaffoldETHDeploy {
  error InvalidPrivateKey(string);

  function run() external {
    uint256 deployerPrivateKey = setupLocalhostEnv();
    if (deployerPrivateKey == 0) {
      revert InvalidPrivateKey(
        "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
      );
    }
    vm.startBroadcast(deployerPrivateKey);

    address owner = vm.addr(deployerPrivateKey);

    YourContract yourContract = new YourContract(vm.addr(deployerPrivateKey));
    console.logString(
      string.concat(
        "YourContract deployed at: ", vm.toString(address(yourContract))
      )
    );

    uint256 initialSupply = 10000000 ether;
    SimpleToken simpleToken = new SimpleToken(initialSupply);
    console.logString(
      string.concat(
        "SimpleToken deployed at: ", vm.toString(address(simpleToken))
      )
    );

    uint256 apy = 12; // APY in percentage
    uint256 frequencyValue = 360;
    uint256 tenor = 30;
    TimelockInterestVault timelockVault = new TimelockInterestVault(owner, simpleToken, apy, frequencyValue, tenor);
    console.logString(
      string.concat(
        "TimelockInterestVault deployed at: ", vm.toString(address(timelockVault))
      )
    );

    vm.stopBroadcast();

    /**
     * This function generates the file containing the contracts Abi definitions.
     * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
     * This function should be called last.
     */
    exportDeployments();
  }

  function test() public { }
}
