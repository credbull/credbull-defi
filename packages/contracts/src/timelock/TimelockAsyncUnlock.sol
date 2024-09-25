// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title RedeemAfterNotice
 */
abstract contract TimelockAsyncUnlock is ITimelockOpenEnded, Context {
    error TimelockAsyncUnlock__NoticePeriodInsufficient(
        address account, uint256 requestedPeriod, uint256 requiredPeriod
    );
    error TimelockAsyncUnlock__RequestedUnlockAmountInsufficient(
        address account, uint256 amountUnlocked, uint256 amount
    );
    error TimelockAsyncUnlock__UnlockPeriodNotReached(address account, uint256 currentPeriod, uint256 redeemPeriod);
    error TimelockAsyncUnlock__RequesterNotOwner(address requester, address owner);

    uint256 public immutable NOTICE_PERIOD;

    struct UnlockItem {
        address account;
        uint256 depositPeriod;
        uint256 redeemPeriod;
        uint256 amount;
    }

    mapping(uint256 depositPeriod => mapping(address account => UnlockItem)) private _unlockRequests;

    constructor(uint256 noticePeriod_) {
        NOTICE_PERIOD = noticePeriod_;
    }

    /// @notice Requests redemption of `amount`, which will be transferred to `receiver` after the `redeemPeriod`.
    // TODO - confirm if we want the concept of shares here, or are these just assets?
    function requestUnlock(uint256 amount, address owner, uint256 depositPeriod, uint256 unlockPeriod) public {
        address requester = _msgSender();
        if (requester != owner) {
            revert TimelockAsyncUnlock__RequesterNotOwner(requester, owner); // TODO - should we check allowances too?
        }

        uint256 depositWithNoticePeriod = depositPeriod + NOTICE_PERIOD;
        if (unlockPeriod < depositWithNoticePeriod) {
            revert TimelockAsyncUnlock__NoticePeriodInsufficient(owner, unlockPeriod, depositWithNoticePeriod);
        }

        uint256 currentWithNoticePeriod = currentPeriod() + NOTICE_PERIOD;
        if (unlockPeriod < currentWithNoticePeriod) {
            revert TimelockAsyncUnlock__NoticePeriodInsufficient(owner, unlockPeriod, currentWithNoticePeriod);
        }

        // TODO - what happens if multiple redeem requests for same user / deposit / redeem tuple?
        _unlockRequests[depositPeriod][owner] =
            UnlockItem({ account: owner, depositPeriod: depositPeriod, redeemPeriod: unlockPeriod, amount: amount });
    }

    /// @notice Unlocks `amount` after the `redeemPeriod`, transferring to `receiver`.
    function unlock(uint256 amount, address owner, uint256 depositPeriod, uint256 unlockPeriod) public {
        address requester = _msgSender();
        if (requester != owner) {
            revert TimelockAsyncUnlock__RequesterNotOwner(requester, owner);
        }

        uint256 currentPeriod_ = currentPeriod();

        // check the redeemPeriod
        if (unlockPeriod > currentPeriod_) {
            revert TimelockAsyncUnlock__UnlockPeriodNotReached(owner, currentPeriod_, unlockPeriod);
        }

        UnlockItem memory unlockRequest = _unlockRequests[depositPeriod][owner];

        // check the redeemPeriod in the unlocks
        if (unlockRequest.redeemPeriod > currentPeriod_) {
            revert TimelockAsyncUnlock__UnlockPeriodNotReached(owner, currentPeriod_, unlockRequest.redeemPeriod);
        }

        // check the redeemPeriod in the unlocks
        if (amount > unlockRequest.amount) {
            revert TimelockAsyncUnlock__RequestedUnlockAmountInsufficient(owner, unlockRequest.amount, amount);
        }

        // TODO - change contract to just "unlock" this amount.  leave it to someone else to burn or redeem.
        _updateLockAfterUnlock(owner, depositPeriod, amount);
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public virtual override {
        unlock(amount, account, depositPeriod, currentPeriod());
    }

    /// @notice Process the lock after successful unlocking
    function _updateLockAfterUnlock(address account, uint256 depositPeriod, uint256 amount) internal virtual;

    /// @dev there's no intermediate "unlocked" state - deposits are locked and then burnt on redeem
    function unlockedAmount(address, /* account */ uint256 /* depositPeriod */ )
        public
        view
        virtual
        override
        returns (uint256 unlockedAmount_)
    {
        return 0; //
    }

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }

    /// @notice Returns the current period.
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);
}
