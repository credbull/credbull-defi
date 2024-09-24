// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockOpenEnded } from "@credbull/timelock/TimelockOpenEnded.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title RedeemAfterNotice
 */
abstract contract RedeemAfterNotice is TimelockOpenEnded, Context {
    error RedeemAfterNotice__NoticePeriodInsufficient(address account, uint256 requestedPeriod, uint256 requiredPeriod);
    error RedeemAfterNotice__RequestedRedeemAmountInsufficient(address account, uint256 amountUnlocked, uint256 amount);
    error RedeemAfterNotice__RedeemPeriodNotReached(address account, uint256 currentPeriod, uint256 redeemPeriod);
    error RedeemAfterNotice__RequesterNotOwner(address requester, address owner);

    uint256 public immutable NOTICE_PERIOD = 1;

    struct UnlockItem {
        address account;
        uint256 depositPeriod;
        uint256 redeemPeriod;
        uint256 amount;
    }
    // Mapping to store unlock requests

    mapping(uint256 depositPeriod => mapping(address account => UnlockItem)) private _unlockRequests;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits) TimelockOpenEnded(deposits) {
        NOTICE_PERIOD = noticePeriod_;
    }

    /// @notice Requests redemption of `amount`, which will be transferred to `receiver` after the `redeemPeriod`.
    // TODO - confirm if we want the concept of shares here, or are these just assets?
    function requestRedeem(uint256 amount, address owner, uint256 depositPeriod, uint256 redeemPeriod) public {
        address requester = _msgSender();
        if (requester != owner) {
            revert RedeemAfterNotice__RequesterNotOwner(requester, owner); // TODO - should we check allowances too?
        }

        uint256 depositWithNoticePeriod = depositPeriod + NOTICE_PERIOD;
        if (redeemPeriod < depositWithNoticePeriod) {
            revert RedeemAfterNotice__NoticePeriodInsufficient(owner, redeemPeriod, depositWithNoticePeriod);
        }

        uint256 currentWithNoticePeriod = currentPeriod() + NOTICE_PERIOD;
        if (redeemPeriod < currentWithNoticePeriod) {
            revert RedeemAfterNotice__NoticePeriodInsufficient(owner, redeemPeriod, currentWithNoticePeriod);
        }

        // TODO - what happens if multiple redeem requests for same user / deposit / redeem tuple?
        _unlockRequests[depositPeriod][owner] =
            UnlockItem({ account: owner, depositPeriod: depositPeriod, redeemPeriod: redeemPeriod, amount: amount });
    }

    /// @notice Processes the redemption of `amount` after the `redeemPeriod`, transferring to `receiver`.
    function redeem(uint256 amount, address, /* receiver */ address owner, uint256 depositPeriod, uint256 redeemPeriod)
        public
    {
        address requester = _msgSender();
        if (requester != owner) {
            revert RedeemAfterNotice__RequesterNotOwner(requester, owner); // TODO - should we check allowances too?
        }

        uint256 currentPeriod_ = currentPeriod();

        // check the redeemPeriod
        if (redeemPeriod > currentPeriod_) {
            revert RedeemAfterNotice__RedeemPeriodNotReached(owner, currentPeriod_, redeemPeriod);
        }

        UnlockItem memory unlockRequest = _unlockRequests[depositPeriod][owner];

        // check the redeemPeriod in the unlocks
        if (unlockRequest.redeemPeriod > currentPeriod_) {
            revert RedeemAfterNotice__RedeemPeriodNotReached(owner, currentPeriod_, unlockRequest.redeemPeriod);
        }

        // check the redeemPeriod in the unlocks
        if (amount > unlockRequest.amount) {
            revert RedeemAfterNotice__RequestedRedeemAmountInsufficient(owner, unlockRequest.amount, amount);
        }

        // TODO - do we want this contract to do redeem or not?  maybe better just to create unlockRequests and unlocks
        DEPOSITS.burn(owner, depositPeriod, amount, _emptyBytesArray()); // deposit specific
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public virtual override {
        redeem(amount, account, account, depositPeriod, currentPeriod());
    }

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
}
