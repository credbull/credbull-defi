// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { DeployAndLoadLiquidMultiTokenVault } from "./DeployAndLoadLiquidMultiTokenVault.s.sol";
import { TestUtil } from "@test/test/util/TestUtil.t.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

contract DeployAndLoadLiquidMultiTokenVaultTest is TestUtil {
    DeployAndLoadLiquidMultiTokenVault internal _deployVault;
    LiquidContinuousMultiTokenVault internal _liquidVault;

    function setUp() public {
        _deployVault = new DeployAndLoadLiquidMultiTokenVault();

        uint256 vaultStartTimestamp = _deployVault.startTimestamp();
        vm.warp(vaultStartTimestamp); // warp to a "real time" time rather than block.timestamp=1

        _liquidVault = _deployVault.run();
    }

    /// @dev - this SHOULD work, but will have knock-off effects to yield/returns and pending requests
    function test__LiquidContinuousMultiTokenVaultUtil__SetPeriod() public {
        // block.timestamp starts at "1" in tests.  warp ahead so we can set time in the past relative to that.
        vm.warp(201441601000); // 201441601000 = May 20, 1976 12:00:01 GMT (a great day!)

        _setPeriodAndAssert(_liquidVault, 0);
        _setPeriodAndAssert(_liquidVault, 30);
        _setPeriodAndAssert(_liquidVault, 100);
        _setPeriodAndAssert(_liquidVault, 50);
        _setPeriodAndAssert(_liquidVault, 10);
    }

    /// @dev - this SHOULD work, but will have knock-off effects to yield/returns and pending requests
    function test__DeployAndLoadLiquidMultiTokenVaultTest__VerifyCutoffs() public {
        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth = _deployVault.auth();

        _setPeriod(vaultAuth.operator, _liquidVault, 0);
        _setPeriod(vaultAuth.operator, _liquidVault, 30);
    }

    function _setPeriod(address operator, LiquidContinuousMultiTokenVault vault, uint256 newPeriod) public {
        uint256 newPeriodInSeconds = newPeriod * 1 days;
        uint256 currentTime = Timer.timestamp();

        uint256 newStartTime =
            currentTime > newPeriodInSeconds ? (currentTime - newPeriodInSeconds) : (newPeriodInSeconds - currentTime);

        vm.prank(operator);
        vault.setVaultStartTimestamp(newStartTime);
    }

    function _setPeriodAndAssert(LiquidContinuousMultiTokenVault vault, uint256 newPeriod) internal {
        LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth = _deployVault.auth();

        assertTrue(
            Timer.timestamp() >= (vault._vaultStartTimestamp() - newPeriod * 24 hours),
            "trying to set period before block.timestamp"
        );

        _setPeriod(vaultAuth.operator, vault, newPeriod);

        assertEq(newPeriod, (block.timestamp - vault._vaultStartTimestamp()) / 24 hours, "timestamp not set correctly");
        assertEq(newPeriod, vault.currentPeriod(), "period not set correctly");
    }
}
