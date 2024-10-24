// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/SimpleOFT.sol";

contract DeploySimpleOFT is ScaffoldETHDeploy {
    function run(address lzEndpoint) external ScaffoldEthDeployerRunner {
        SimpleOFT simpleOFT = new SimpleOFT("SimpleOFT", "SOFT", 6, lzEndpoint, 1_000_000 ether);

      
        console.logString(
            string.concat(
                "SimpleOFT contract deployed at: ", vm.toString(address(simpleOFT))
            )
        );
    }
}
