// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { CredbullEntities } from "../src/CredbullEntities.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployVault is Script {
    uint256 private constant PROMISED_FIXED_YIELD = 10;

    function run() external returns (CredbullVault[] memory, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        this.deployCredbullEntities(helperConfig);

        uint256 firstVaultOpensAt = vm.envUint("VAULT_OPENS_AT_TIMESTAMP");

        CredbullVault[] memory vaults = new CredbullVault[](3);
        vaults[0] = this.deployFixedYieldVault(helperConfig, PROMISED_FIXED_YIELD, firstVaultOpensAt);
        vaults[1] = this.deployFixedYieldVault(helperConfig, PROMISED_FIXED_YIELD, firstVaultOpensAt + 1 weeks);
        vaults[2] = this.deployFixedYieldVault(helperConfig, PROMISED_FIXED_YIELD, firstVaultOpensAt + 2 weeks);

        return (vaults, helperConfig);
    }

    function deployFixedYieldVault(HelperConfig helperConfig, uint256 promisedYield, uint256 opensAt)
        external
        returns (CredbullVault)
    {
        (address owner, address asset, string memory shareName, string memory shareSymbol, address custodian,,) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        CredbullVault vault = new CredbullVault(
            owner,
            IERC20(asset),
            shareName,
            shareSymbol,
            promisedYield,
            opensAt,
            opensAt + 1 minutes,
            custodian
        );
        vm.stopBroadcast();

        return vault;
    }

    function deployCredbullEntities(HelperConfig helperConfig) external returns (CredbullEntities) {
        (,,,, address custodian, address treasury, address activityReward) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        CredbullEntities entities = new CredbullEntities(custodian, treasury, activityReward);
        vm.stopBroadcast();

        return entities;
    }
}
