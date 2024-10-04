//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/SimpleUSDC.sol";
import "../contracts/yield/LiquidContinuousMultiTokenVault.sol";
import "../contracts/yield/strategy/TripleRateYieldStrategy.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract DeployScript is ScaffoldETHDeploy {
  error InvalidPrivateKey(string);

  IYieldStrategy _yieldStrategy = new TripleRateYieldStrategy();

  // struct VaultParams {
  //   address contractOwner;
  //   IERC20Metadata asset;
  //   IYieldStrategy yieldStrategy;
  //   uint256 vaultStartTimestamp;
  //   uint256 redeemNoticePeriod;
  //   uint256 fullRateScaled;
  //   uint256 reducedRateScaled;
  //   uint256 frequency; // MUST be a daily frequency, either 360 or 365
  //   uint256 tenor;
  // }

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
    
    // give the vaults some "reserve" for interest payment
    uint256 vaultReserve = 10_000 * SCALE;

    LiquidContinuousMultiTokenVault.VaultParams memory params = LiquidContinuousMultiTokenVault.VaultParams({
        contractOwner: owner,
        contractOperator: user,
        asset: simpleUSDC,
        yieldStrategy: _yieldStrategy,
        vaultStartTimestamp: block.timestamp,
        redeemNoticePeriod: 1 days,
        fullRateScaled: 1000 * SCALE,
        reducedRateScaled: 500 * SCALE,
        frequency: 365,
        tenor: 30
    });

    LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(params);

    vm.stopBroadcast();


    vm.startBroadcast(userPrivateKey);

    uint256 userMintAmount = 100_000 * SCALE;

    simpleUSDC.mint(address(user), userMintAmount);

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
