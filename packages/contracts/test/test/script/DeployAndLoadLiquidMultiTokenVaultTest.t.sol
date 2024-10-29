// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";
import { DeployAndLoadLiquidMultiTokenVault } from "./DeployAndLoadLiquidMultiTokenVault.s.sol";

contract DeployAndLoadLiquidMultiTokenVaultTest is LiquidContinuousMultiTokenVaultTestBase {
    DeployAndLoadLiquidMultiTokenVault internal _deployVault;

    function setUp() public override {
        _deployVault = new DeployAndLoadLiquidMultiTokenVault();

        uint256 vaultStartTimestamp = _deployVault.startTimestamp();
        vm.warp(vaultStartTimestamp); // warp to a "real time" time rather than block.timestamp=1

        _liquidVault = _deployVault.run();
    }

    /// @dev - this SHOULD work, but will have knock-off effects to yield/returns and pending requests
    function test__DeployAndLoadLiquidMultiTokenVaultTest__VerifyCutoffs() public {
        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth = _deployVault.auth();

        _setPeriod(vaultAuth.operator, _liquidVault, 0);
        _setPeriod(vaultAuth.operator, _liquidVault, 30);
    }
}
