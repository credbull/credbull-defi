// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { CredbullEntities } from "../src/CredbullEntities.sol";
import { HelperConfig, NetworkConfig, TimeConfig } from "./HelperConfig.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployVault is Script {
    uint256 private constant PROMISED_FIXED_YIELD = 10;

    function run() external returns (CredbullVault[] memory, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();

        this.deployCredbullEntities(helperConfig);

        TimeConfig memory time = helperConfig.getTimeConfig();

        CredbullVault[] memory vaults = new CredbullVault[](3);
        vaults[0] = this.deployFixedYieldVault(
            helperConfig, PROMISED_FIXED_YIELD, time.firstVaultOpensAt, time.vaultClosesDuration
        );
        vaults[1] = this.deployFixedYieldVault(
            helperConfig,
            PROMISED_FIXED_YIELD,
            time.firstVaultOpensAt + 1 * time.vaultClosesDuration,
            time.vaultClosesDuration
        );
        vaults[2] = this.deployFixedYieldVault(
            helperConfig,
            PROMISED_FIXED_YIELD,
            time.firstVaultOpensAt + 2 * time.vaultClosesDuration,
            time.vaultClosesDuration
        );

        return (vaults, helperConfig);
    }

    function deployFixedYieldVault(
        HelperConfig helperConfig,
        uint256 promisedYield,
        uint256 opensAt,
        uint256 closesDuration
    ) external returns (CredbullVault) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.startBroadcast();
        CredbullVault vault = new CredbullVault(
            config, IERC20(config.asset), promisedYield, opensAt, opensAt + closesDuration
        );
        vm.stopBroadcast();

        return vault;
    }

    function deployCredbullEntities(HelperConfig helperConfig) external returns (CredbullEntities) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.startBroadcast();
        CredbullEntities entities =
            new CredbullEntities(config.custodian, config.kycProvider, config.treasury, config.activityReward);
        vm.stopBroadcast();

        return entities;
    }
}
