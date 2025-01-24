// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ITimelock } from "@credbull/timelock/ITimelock.sol";
import { PureStone } from "@credbull/yield/PureStone.sol";
import { DiscountVault } from "@credbull/token/ERC4626/DiscountVault.sol";
import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IVaultVerifierBase } from "@test/test/token/ERC4626/IVaultVerifierBase.t.sol";

import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract PureStoneVerifier is IVaultVerifierBase {
    /// @dev verify redeem.  updates vault assets and shares.
    function _verifyRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) public virtual override returns (uint256 actualAssetsAtPeriod_) {
        PureStone pureStone = PureStone(address(vault));

        // check if there's sufficient shares available to redeem
        uint256 maxUnlock = pureStone.maxUnlock(redeemUsers.tokenOperator, testParam.redeemPeriod);

        // ------------------- redeem success (enough shares to unlock)  -------------------

        if (maxUnlock > sharesToRedeemAtPeriod) {
            return super._verifyRedeemOnly(redeemUsers, vault, testParam, sharesToRedeemAtPeriod);
        }

        // ------------------- redeem failure (insufficient shares to unlock)  -------------------

        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        _warpToPeriod(vault, testParam.redeemPeriod); // warp the vault to redeem period

        // authorize the tokenOperator
        _approveForAll(vault, redeemUsers.tokenOwner, redeemUsers.tokenOperator, true);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.ITimelock_ExceededMaxUnlock.selector,
                redeemUsers.tokenOperator,
                testParam.redeemPeriod,
                sharesToRedeemAtPeriod,
                maxUnlock
            )
        );
        vm.startPrank(redeemUsers.tokenOperator);
        uint256 actualAssetsAtPeriod = vault.redeemForDepositPeriod(
            sharesToRedeemAtPeriod, redeemUsers.tokenReceiver, redeemUsers.tokenOwner, testParam.depositPeriod
        );
        vm.stopPrank();

        // de-authorize the tokenOperator
        _approveForAll(vault, redeemUsers.tokenOwner, redeemUsers.tokenOperator, false);

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore the vault to previous state

        return actualAssetsAtPeriod;
    }

    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        override
        returns (uint256 expectedShares)
    {
        PureStone pureStone = PureStone(address(vault));
        uint256 scale = 10 ** IERC20Metadata(pureStone.asset()).decimals();

        return CalcDiscounted.calcDiscounted(testParam.principal, pureStone.price(), scale);
    }

    function _isRedeemAtTenor(PureStone pureStone, TestParamSet.TestParam memory testParam)
        internal
        view
        virtual
        returns (bool isRedeemAtTenor)
    {
        return (testParam.redeemPeriod == testParam.depositPeriod + pureStone._tenor());
    }

    function _expectedAssets(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        virtual
        override
        returns (uint256 expectedReturns_)
    {
        PureStone pureStone = PureStone(address(vault));

        return _isRedeemAtTenor(pureStone, testParam) ? testParam.principal + _expectedReturns(vault, testParam) : 0;
    }

    function _expectedReturns(IVault vault, TestParamSet.TestParam memory testParam)
        public
        view
        override
        returns (uint256 expectedReturns_)
    {
        PureStone pureStone = PureStone(address(vault));

        return _isRedeemAtTenor(pureStone, testParam) ? pureStone.calcYieldSingleTenor(testParam.principal) : 0;
    }

    /// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
    // // TODO - set(remove) the max allowance for the operator
    function _approveForAll(IVault vault, address owner, address operator, bool approved) internal virtual override {
        PureStone pureStone = PureStone(address(vault));

        uint256 balanceToApprove = approved ? pureStone.balanceOf(owner) : 0;

        vm.prank(owner);
        pureStone.approve(operator, balanceToApprove);
    }

    function _warpToPeriod(IVault vault, uint256 timePeriod) public virtual override {
        DiscountVault discountVault = DiscountVault(address(vault));

        uint256 warpToTimeInSeconds = discountVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }
}
