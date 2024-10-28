// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/StargateUSDCBridge.sol";

contract DeployStargateUSDCBridge is ScaffoldETHDeploy {
    // ArbitrumSepolia
    address _router = 0x2a4C2F5ffB0E0F2dcB3f9EBBd442B8F77ECDB9Cc;
    address _token = 0x3253a335E7bFfB4790Aa4C25C4250d206E9b9773;
    // OptimismSepolia
    // address _router = 0xa2dfFdDc372C6aeC3a8e79aAfa3953e8Bc956D63;
    // address _token = 0x488327236B65C61A6c083e8d811a4E0D3d1D4268;

    function run() external ScaffoldEthDeployerRunner {
        StargateUSDCBridge stargateUSDCBridge = new StargateUSDCBridge(_router, _token);

      
        console.logString(
            string.concat(
                "StargateUSDCBridge contract deployed at: ", vm.toString(address(stargateUSDCBridge))
            )
        );
    }
}
