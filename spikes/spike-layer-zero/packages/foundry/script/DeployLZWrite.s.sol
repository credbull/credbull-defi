// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/LZWrite.sol";

contract DeployLZWrite is ScaffoldETHDeploy {
    function run(address lzEndpoint) external ScaffoldEthDeployerRunner {
        LZWrite lzWrite = new LZWrite(lzEndpoint);

      
        console.logString(
            string.concat(
                "LZWrite contract deployed at: ", vm.toString(address(lzWrite))
            )
        );
    }
}
