//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/kk/YieldSubscription.sol";
import "./DeployHelpers.s.sol";
import "../contracts/SimpleUSDC.sol";

import { TimelockInterestVault } from "@credbull-spike/contracts/ian/fixed/TimelockInterestVault.sol";

contract DeployScript is ScaffoldETHDeploy {
  error InvalidPrivateKey(string);

  function run() external {
    uint256 deployerPrivateKey = setupLocalhostEnv();
    uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
  
    if (deployerPrivateKey == 0) {
      revert InvalidPrivateKey(
        "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
      );
    }
    vm.startBroadcast(deployerPrivateKey);
    address owner = vm.addr(deployerPrivateKey);
    address user = vm.addr(userPrivateKey);

    console.logString(string.concat("Owner / Deployer address = ", vm.toString(owner)));

    uint256 MINT_AMOUNT = 10_000_000_000_000; //10 Million

    SimpleUSDC simpleUSDC = new SimpleUSDC(MINT_AMOUNT); //10 Million
    console.logString(
      string.concat(
        "SimpleUSDC deployed at: ", vm.toString(address(simpleUSDC))
      )
    );

    uint256 maturityPeriod = 30;
    uint256 coolDownPeriod = 2;

    YieldSubscription shortTermYield = new YieldSubscription(address(simpleUSDC), 1724112000, maturityPeriod, coolDownPeriod);
    console.logString(
      string.concat(
        "Short term yield deployed at: ", vm.toString(address(shortTermYield))
      )
    );

    YieldSubscription shortTermYieldRollover = new YieldSubscription(address(simpleUSDC), 1724112000, maturityPeriod, coolDownPeriod);
    console.logString(
      string.concat(
        "Short term yield rollover deployed at: ", vm.toString(address(shortTermYieldRollover))
      )
    );
    vm.stopBroadcast();

    vm.startBroadcast(userPrivateKey);

    simpleUSDC.mint(address(user), MINT_AMOUNT); //10 Million
    simpleUSDC.approve(address(shortTermYield), MINT_AMOUNT); //10 Million
    simpleUSDC.approve(address(shortTermYieldRollover), MINT_AMOUNT); //10 Million

    shortTermYield.setCurrentTimePeriodsElapsed(1);
    shortTermYieldRollover.setCurrentTimePeriodsElapsed(1);

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
