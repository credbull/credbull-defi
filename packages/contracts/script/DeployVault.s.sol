// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployVault is Script {
    uint256 private constant PROMISED_FIXED_YIELD = 10;

    CredbullVault private vault;

    function run() external returns (CredbullVault, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        vault = this.deployFixedYieldVault(helperConfig, PROMISED_FIXED_YIELD);

        return (vault, helperConfig);
    }

    function deployFixedYieldVault(HelperConfig helperConfig, uint256 promisedYield) external returns (CredbullVault) {
        (address owner, address asset, string memory shareName, string memory shareSymbol, address custodian) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        vault = new CredbullVault(owner, IERC20(asset), shareName, shareSymbol, custodian, promisedYield);
        vm.stopBroadcast();

        return vault;
    }
}
