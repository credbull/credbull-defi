//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/YourContract.sol";
import "../contracts/AxelarBridge.sol";
import "./DeployHelpers.s.sol";

contract DeployYourContract is ScaffoldETHDeploy {
  // use `deployer` from `ScaffoldETHDeploy`
  function run() external ScaffoldEthDeployerRunner {
    YourContract yourContract = new YourContract(deployer);
    AxelarBridge axelarBridge = new AxelarBridge(
      address(0xe1cE95479C84e9809269227C7F8524aE051Ae77a),
      address(0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6)
    );
    console.logString(
      string.concat(
        "YourContract deployed at: ", vm.toString(address(yourContract))
      )
    );
    console.logString(
      string.concat(
        "AxelarBridge deployed at: ", vm.toString(address(axelarBridge))
      )
    );
  }
}
