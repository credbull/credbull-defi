// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

import { MultiTokenVaultDailyPeriods } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriods.t.sol";
import { IMultiTokenVaultVerifierBase } from "@test/test/token/ERC1155/IMultiTokenVaultVerifierBase.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract MultiTokenVaultDailyPeriodsVerifier is IMultiTokenVaultVerifierBase {
    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        override
        returns (uint256 expectedShares)
    {
        MultiTokenVaultDailyPeriods multiTokenVault = MultiTokenVaultDailyPeriods(address(vault));

        return testParam.principal / multiTokenVault.ASSET_TO_SHARES_RATIO();
    }

    function _expectedReturns(uint256, /* shares */ IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        override
        returns (uint256 expectedReturns_)
    {
        return MultiTokenVaultDailyPeriods(address(vault))._yieldStrategy().calcYield(
            address(vault), testParam.principal, testParam.depositPeriod, testParam.redeemPeriod
        );
    }

    function _warpToPeriod(IVault vault, uint256 timePeriod) public override {
        MultiTokenVaultDailyPeriods multiTokenVault = MultiTokenVaultDailyPeriods(address(vault));

        uint256 warpToTimeInSeconds = multiTokenVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }
}
