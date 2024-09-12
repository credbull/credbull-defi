//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/kk/YieldSubscription.sol";
import "./DeployHelpers.s.sol";
import "../contracts/SimpleUSDC.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { TimelockInterestVault } from "@credbull-contracts/contracts/interest/TimelockInterestVault.sol";

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

    uint256 SCALE = 1 * 10 ** 6;
    uint256 INITIAL_SUPPLY = 10_000_000 * SCALE; // 10 million, scaled

    SimpleUSDC simpleUSDC = new SimpleUSDC(INITIAL_SUPPLY); //10 Million
    console.logString(string.concat("SimpleUSDC deployed at: ", vm.toString(address(simpleUSDC))));

    uint8 interestRate = 6;
    uint256 frequency = 360;
    uint8 tenor = 30;

    TimelockInterestVault timeLockVaultScenario1 =
      new TimelockInterestVault(owner, IERC20Metadata(address(simpleUSDC)), interestRate, frequency, tenor);
    console.logString(
      string.concat("TimelockInterestVault-1 deployed at: ", vm.toString(address(timeLockVaultScenario1)))
    );

    TimelockInterestVault timeLockVaultScenario2 =
      new TimelockInterestVault(owner, IERC20Metadata(address(simpleUSDC)), interestRate, frequency, tenor);
    console.logString(
      string.concat("TimelockInterestVault-2 deployed at: ", vm.toString(address(timeLockVaultScenario2)))
    );

    // give the vaults some "reserve" for interest payment
    uint256 vaultReserve = 10_000 * SCALE;
    simpleUSDC.transfer(address(timeLockVaultScenario1), vaultReserve);
    simpleUSDC.transfer(address(timeLockVaultScenario2), vaultReserve);

    timeLockVaultScenario1.setCurrentTimePeriodsElapsed(0);
    timeLockVaultScenario2.setCurrentTimePeriodsElapsed(0);

    vm.stopBroadcast();


    vm.startBroadcast(userPrivateKey);

    uint256 userMintAmount = 100_000 * SCALE;

    simpleUSDC.mint(address(user), userMintAmount);
    simpleUSDC.approve(address(timeLockVaultScenario1), userMintAmount);
    simpleUSDC.approve(address(timeLockVaultScenario2), userMintAmount);


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
