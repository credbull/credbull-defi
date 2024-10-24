// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/LZMoneyTransfer.sol";

contract DeployLZMoneyTransfer is ScaffoldETHDeploy {
    function run(address lzEndpoint) external ScaffoldEthDeployerRunner {
        LZMoneyTransfer lzMoneyTransfer = new LZMoneyTransfer(lzEndpoint);

      
        console.logString(
            string.concat(
                "LZMoneyTransfer contract deployed at: ", vm.toString(address(lzMoneyTransfer))
            )
        );
    }
}
