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

        (uint256 firstVaultOpensAt, uint256 vaultClosesDuration) = helperConfig.activeTimeConfig();

        CredbullVault[] memory vaults = new CredbullVault[](3);
        vaults[0] =
            this.deployFixedYieldVault(helperConfig, PROMISED_FIXED_YIELD, firstVaultOpensAt, vaultClosesDuration);
        vaults[1] = this.deployFixedYieldVault(
            helperConfig, PROMISED_FIXED_YIELD, firstVaultOpensAt + 1 * vaultClosesDuration, vaultClosesDuration
        );
        vaults[2] = this.deployFixedYieldVault(
            helperConfig, PROMISED_FIXED_YIELD, firstVaultOpensAt + 2 * vaultClosesDuration, vaultClosesDuration
        );

        return (vaults, helperConfig);
    }

    function deployFixedYieldVault(
        HelperConfig helperConfig,
        uint256 promisedYield,
        uint256 opensAt,
        uint256 closesDuration
    ) external returns (CredbullVault) {
        (address owner, address asset, string memory shareName, string memory shareSymbol, address custodian,,) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        CredbullVault vault = new CredbullVault(
            owner, IERC20(asset), shareName, shareSymbol, promisedYield, opensAt, opensAt + closesDuration, custodian
        );
        _setRules(vault);
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

    function _setRules(CredbullVault vault) internal {
        vault.setRules(CredbullVault.Rules({ checkMaturity: true, checkVaultOpenStatus: true, checkWhitelist: true }));
    }
}
