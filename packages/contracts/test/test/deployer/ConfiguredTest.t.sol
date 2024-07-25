// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { CBLConfigured, VaultsSupportConfigured } from "@script/deployer/Configured.s.sol";

/// @dev A [Test] type that loads the Test Configuration and provides access to Vaults and Vaults Support
///     Distribution Unit configuration.
abstract contract VaultsSupportConfiguredTest is Test, VaultsSupportConfigured {
    /// @dev Returns the Test Environment discriminator.
    function environment() internal pure override returns (string memory) {
        return "test";
    }
}

/// @dev A [Test] type that loads the Test Configuration and provides access to CBL Distribution Unit configuration.
abstract contract CBLConfiguredTest is Test, CBLConfigured {
    /// @dev Returns the Test Environment discriminator.
    function environment() internal pure override returns (string memory) {
        return "test";
    }
}
