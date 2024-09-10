//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/kk/YieldSubscription.sol";
import "./DeployHelpers.s.sol";
import "../contracts/SimpleUSDC.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

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

    uint8 interestRate = 6;
    uint8 frequency = 1;
    uint8 tenor = 30;

    TimelockInterestVault timeLockVaultScenario1 = new TimelockInterestVault(
      owner,
      IERC20Metadata(address(simpleUSDC)),
      interestRate,
      frequency,
      tenor
    );

    TimelockInterestVault timeLockVaultScenario2 = new TimelockInterestVault(
      owner,
      IERC20Metadata(address(simpleUSDC)),
      interestRate,
      frequency,
      tenor
    );

    vm.stopBroadcast();

    vm.startBroadcast(userPrivateKey);

    simpleUSDC.mint(address(user), MINT_AMOUNT); //10 Million
    simpleUSDC.approve(address(timeLockVaultScenario1), MINT_AMOUNT); //10 Million
    simpleUSDC.approve(address(timeLockVaultScenario2), MINT_AMOUNT); //10 Million

    timeLockVaultScenario1.setCurrentTimePeriodsElapsed(1);
    timeLockVaultScenario2.setCurrentTimePeriodsElapsed(1);

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
