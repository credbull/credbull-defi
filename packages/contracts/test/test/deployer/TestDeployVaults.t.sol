// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { DeployVaults, DeployVaultsSupport } from "@script/deployer/DeployVaults.s.sol";

/// @notice The [Script] used to deploy the Credbull Vaults Distribution.
contract TestDeployVaults is DeployVaults {
    /// @dev Returns the Test Environment discriminator.
    function environment() internal pure override returns (string memory) {
        return "test";
    }
}

/// @notice The [Script] for deploying the Vaults Support Distribution Unit.
contract TestDeployVaultsSupport is DeployVaultsSupport {
    /// @dev Returns the Test Environment discriminator.
    function environment() internal pure override returns (string memory) {
        return "test";
    }
}
