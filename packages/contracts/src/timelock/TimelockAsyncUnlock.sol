// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title TimelockAsyncUnlock
 */
abstract contract TimelockAsyncUnlock is ITimelockOpenEnded, Context {
    struct UnlockItem {
        address account;
        uint256 depositPeriod;
        uint256 unlockPeriod;
        uint256 amount;
    }

    uint256 public immutable NOTICE_PERIOD;

    mapping(uint256 depositPeriod => mapping(address account => UnlockItem)) private _unlockRequests;

    error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(address account, uint256 period, uint256 depositPeriod);
    error TimelockAsyncUnlock__UnlockBeforeCurrentPeriod(address account, uint256 period, uint256 currentPeriod);
    error TimelockAsyncUnlock__UnlockPeriodMismatch(
        address account, uint256 unlockPeriod, uint256 requestedUnlockPeriod
    );
    error TimelockAsyncUnlock__RequestBeforeDepositWithNoticePeriod(
        address account, uint256 period, uint256 depositWithNoticePeriod
    );
    error TimelockAsyncUnlock__RequestBeforeCurrentWithNoticePeriod(
        address account, uint256 period, uint256 currentWithNoticePeriod
    );
    error TimelockAsyncUnlock__RequesterNotOwner(address requester, address tokenOwner);

    /// @notice Modifier to ensure only the token owner can call the function
    modifier onlyTokenOwner(address tokenOwner) {
        if (_msgSender() != tokenOwner) {
            revert TimelockAsyncUnlock__RequesterNotOwner(_msgSender(), tokenOwner);
        }
        _;
    }

    /// @notice Modifier to check if the unlock request period is valid
    modifier validateRequestPeriod(uint256 depositPeriod, uint256 unlockPeriod) {
        uint256 depositWithNoticePeriod = depositPeriod + NOTICE_PERIOD;
        if (unlockPeriod < depositWithNoticePeriod) {
            // unlocking before depositing!
            revert TimelockAsyncUnlock__RequestBeforeDepositWithNoticePeriod(
                _msgSender(), unlockPeriod, depositWithNoticePeriod
            );
        }

        uint256 currentWithNoticePeriod = currentPeriod() + NOTICE_PERIOD;
        if (unlockPeriod < currentWithNoticePeriod) {
            revert TimelockAsyncUnlock__RequestBeforeCurrentWithNoticePeriod(
                _msgSender(), unlockPeriod, currentWithNoticePeriod
            );
        }
        _;
    }

    /// @notice Modifier to check if the unlock request period is valid
    modifier validateUnlockPeriod(uint256 depositPeriod, uint256 unlockPeriod) {
        if (unlockPeriod < depositPeriod) {
            revert TimelockAsyncUnlock__UnlockBeforeDepositPeriod(_msgSender(), unlockPeriod, depositPeriod);
        }

        if (unlockPeriod < currentPeriod()) {
            revert TimelockAsyncUnlock__UnlockBeforeCurrentPeriod(_msgSender(), unlockPeriod, currentPeriod());
        }
        _;
    }

    constructor(uint256 noticePeriod_) {
        NOTICE_PERIOD = noticePeriod_;
    }

    /// @notice Requests unlocking of `amount`, which will be available after the `unlockPeriod`.
    function requestUnlock(address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount)
    public
    onlyTokenOwner(tokenOwner)
    validateRequestPeriod(depositPeriod, unlockPeriod)
    {
        UnlockItem storage unlockRequest = _unlockRequests[depositPeriod][tokenOwner];

        // TODO - add check for maxRequestUnlock() here

        if (unlockRequest.amount > 0 && unlockRequest.unlockPeriod == unlockPeriod) {
            // Add to the existing unlock request if the unlockPeriod is the same
            unlockRequest.amount += amount;
        } else {
            // Overwrite the unlock request if it's a different unlockPeriod
            _unlockRequests[depositPeriod][tokenOwner] = UnlockItem({
                account: tokenOwner,
                depositPeriod: depositPeriod,
                unlockPeriod: unlockPeriod,
                amount: amount
            });
        }
    }

    /// @notice Unlocks `amount` after the `redeemPeriod`, transferring to `tokenOwner`.
    function unlock(address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount)
    public
    onlyTokenOwner(tokenOwner)
    validateUnlockPeriod(depositPeriod, unlockPeriod)
    {
        UnlockItem storage unlockRequest = _unlockRequests[depositPeriod][tokenOwner];

        if (amount > unlockRequest.amount) {
            revert ITimelockOpenEnded__ExceededMaxUnlock(tokenOwner, amount, unlockRequest.amount);
        }

        // TODO - add check for maxUnlock() here

        // maybe being too strict?  user can just call this again with the "right" unlockPeriod
        if (unlockPeriod != unlockRequest.unlockPeriod) {
            revert TimelockAsyncUnlock__UnlockPeriodMismatch(tokenOwner, unlockPeriod, unlockRequest.unlockPeriod);
        }

        unlockRequest.amount -= amount;

        // Process the unlock
        _updateLockAfterUnlock(tokenOwner, depositPeriod, amount);
    }

    /// @notice Unlocks `amount` of tokens for `tokenOwner` from the given `depositPeriod`.
    function unlock(address tokenOwner, uint256 depositPeriod, uint256 amount) public virtual override {
        unlock(tokenOwner, depositPeriod, currentPeriod(), amount);
    }

    /// @dev there's no "unlocked" state.  deposits are locked => requested to be unlocked => redeemed
    function lockedAmount(address, /* tokenOwner */ uint256 /* depositPeriod */ )
    public
    view
    virtual
    returns (uint256 lockedAmount_);

    /// @dev there's no "unlocked" state.  deposits are locked => requested to be unlocked => redeemed
    function unlockedAmount(address, /* tokenOwner */ uint256 /* depositPeriod */ )
    public
    view
    virtual
    override
    returns (uint256 unlockedAmount_)
    {
        return 0;
    }

    /// @dev there's no "unlocked" state.  deposits are locked => requested to be unlocked => redeemed
    function unlockRequested(address tokenOwner, uint256 depositPeriod)
    public
    view
    virtual
    returns (UnlockItem memory requestUnlockItem_)
    {
        return _unlockRequests[depositPeriod][tokenOwner];
    }

    /// @notice Returns the max amount that can be REQUESTED to be unlocked for `account` at `depositPeriod`.
    /// @notice Returns the max amount that can be REQUESTED to be unlocked for `account` at `depositPeriod`.
    function maxRequestUnlock(address tokenOwner, uint256 depositPeriod)
    public
    view
    virtual
    returns (uint256 maxRequestUnlockAmount)
    {
        UnlockItem memory unlockRequestAmount = _unlockRequests[depositPeriod][tokenOwner];

        return maxUnlock(tokenOwner, depositPeriod) - unlockRequestAmount.amount;
    }

    /// @notice Returns the max amount that can be unlocked for `account` at `lockReleasePeriod`.
    function maxUnlock(address tokenOwner, uint256 depositPeriod)
    public
    view
    virtual
    returns (uint256 maxUnlockAmount)
    {
        return lockedAmount(tokenOwner, depositPeriod) - unlockedAmount(tokenOwner, depositPeriod);
    }

    /// @notice Returns the current period.
    function noticePeriod() public view virtual returns (uint256 noticePeriod_) {
        return NOTICE_PERIOD;
    }

    /// @notice Returns the current period.
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    /// @notice Process the lock after successful unlocking
    function _updateLockAfterUnlock(address tokenOwner, uint256 depositPeriod, uint256 amount) internal virtual;

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }
}
