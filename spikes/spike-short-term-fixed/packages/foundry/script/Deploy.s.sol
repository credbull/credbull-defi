//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/kk/YieldSubscription.sol";
import "./DeployHelpers.s.sol";
import "../contracts/kk/SimpleUSDC.sol";

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

    SimpleUSDC simpleUSDC = new SimpleUSDC(10_000_000_000_000); //10 Million

    YieldSubscription shortTermYield = new YieldSubscription(address(simpleUSDC), 1724112000);
    console.logString(
      string.concat(
        "Short term yield deployed at: ", vm.toString(address(shortTermYield))
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
