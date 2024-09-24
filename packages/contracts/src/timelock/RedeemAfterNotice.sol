// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockOpenEnded } from "@credbull/timelock/TimelockOpenEnded.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

/**
 * @title IAsyncRedeem
 */
abstract contract RedeemAfterNotice is TimelockOpenEnded {
    uint256 public immutable NOTICE_PERIOD = 1;

    struct UnlockItem {
        address account;
        uint256 depositPeriod;
        uint256 redeemPeriod;
        uint256 shares;
    }
    // Mapping to store unlock requests

    mapping(uint256 depositPeriod => mapping(address account => UnlockItem)) private _unlockRequests;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits) TimelockOpenEnded(deposits) {
        NOTICE_PERIOD = noticePeriod_;
    }

    /// @notice Requests redemption of `shares` for assets, which will be transferred to `receiver` after the `redeemPeriod`.
    // TODO - confirm if we want the concept of shares here, or are these just assets?
    function requestRedeem(uint256 shares, address owner, uint256 depositPeriod, uint256 redeemPeriod)
        external
        returns (uint256 assets)
    {
        uint256 minRequestRedeemPeriod = _minRequestRedeemPeriod();

        if (redeemPeriod < minRequestRedeemPeriod) {
            revert ITimelockOpenEnded__NoticePeriodInsufficient(owner, redeemPeriod, minRequestRedeemPeriod);
        }

        // TODO - what happens if multiple redeem requests for same user / deposit / redeem tuple?
        _unlockRequests[depositPeriod][owner] =
            UnlockItem({ account: owner, depositPeriod: depositPeriod, redeemPeriod: redeemPeriod, shares: shares });

        return shares;
    }

    /// @notice Processes the redemption of `shares` for assets after the `redeemPeriod`, transferring to `receiver`.
    // TODO - confirm if we want the concept of shares here, or are these just assets?
    function redeem(uint256 shares, address, /* receiver */ address owner, uint256 depositPeriod, uint256 redeemPeriod)
        public
        returns (uint256 assets)
    {
        uint256 currentPeriod_ = currentPeriod();

        // check the redeemPeriod
        if (redeemPeriod > currentPeriod_) {
            revert ITimelockOpenEnded__RedeemPeriodNotReached(owner, currentPeriod_, redeemPeriod);
        }

        UnlockItem memory unlockRequest = _unlockRequests[depositPeriod][owner];
        // TODO - check null case unlockRequest

        // check the redeemPeriod in the unlocks
        if (unlockRequest.redeemPeriod > currentPeriod_) {
            revert ITimelockOpenEnded__RedeemPeriodNotReached(owner, currentPeriod_, unlockRequest.redeemPeriod);
        }

        // check the redeemPeriod in the unlocks
        if (shares > unlockRequest.shares) {
            revert ITimelockOpenEnded__RequestedUnlockedBalanceInsufficient(owner, unlockRequest.shares, shares);
        }

        // TODO - we need a conversion between shares and assets if we are doing this

        // TODO - do we want this contract to do redeem or not?  maybe better just to create unlockRequests and unlocks
        DEPOSITS.burn(owner, depositPeriod, shares, _emptyBytesArray()); // deposit specific

        return shares;
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public virtual override {
        redeem(amount, account, account, depositPeriod, currentPeriod());
    }

    function unlockedAmount(address, /* account */ uint256 /* depositPeriod */ )
        public
        view
        virtual
        override
        returns (uint256 unlockedAmount_)
    {
        return 0; // no "unlocked" state - deposits are locked and then burnt on redeem
    }

    function _minRequestRedeemPeriod() internal view virtual returns (uint256 minRedeemPeriod_) {
        return currentPeriod() + NOTICE_PERIOD;
    }

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }
}
