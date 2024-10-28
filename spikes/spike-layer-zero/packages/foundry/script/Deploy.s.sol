//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import { DeployLZWrite } from "./DeployLZWrite.s.sol";
import { DeployLZMoneyTransfer } from "./DeployLZMoneyTransfer.s.sol";
import { DeployStargateUSDCBridge } from "./DeployStargateUSDCBridge.s.sol";
import { DeploySimpleOFT } from "./DeploySimpleOFT.s.sol";

contract DeployScript is ScaffoldETHDeploy {
  // address public lzEndpoint = 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3; // Arbitrum
  address public lzEndpoint = 0x55370E0fBB5f5b8dAeD978BA1c075a499eB107B8; // Optimism
  function run() external {
    // DeployLZWrite deployLZWrite = new DeployLZWrite();
    // deployLZWrite.run(lzEndpoint);

    // DeployLZMoneyTransfer deployLZMoneyTransfer = new DeployLZMoneyTransfer();
    // deployLZMoneyTransfer.run(lzEndpoint);

    DeployStargateUSDCBridge deployStargateUSDCBridge = new DeployStargateUSDCBridge();
    deployStargateUSDCBridge.run();

    // DeploySimpleOFT deploySimpleOFT = new DeploySimpleOFT();
    // deploySimpleOFT.run(lzEndpoint);
  }
}
