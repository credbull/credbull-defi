// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title TimelockAsyncUnlock
 */
abstract contract TimelockAsyncUnlock is ITimelockOpenEnded, Context {
    error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(address account, uint256 period, uint256 depositPeriod);
    error TimelockAsyncUnlock__UnlockBeforeCurrentPeriod(address account, uint256 period, uint256 currentPeriod);
    error TimelockAsyncUnlock__RequestBeforeDepositPeriod(
        address account, uint256 period, uint256 depositWithNoticePeriod
    );
    error TimelockAsyncUnlock__RequestBeforeCurrentPeriod(
        address account, uint256 period, uint256 currentWithNoticePeriod
    );

    error TimelockAsyncUnlock__RequesterNotOwner(address requester, address tokenOwner);

    uint256 public immutable NOTICE_PERIOD;

    struct UnlockItem {
        address account;
        uint256 depositPeriod;
        uint256 unlockPeriod;
        uint256 amount;
    }

    mapping(uint256 depositPeriod => mapping(address account => UnlockItem)) private _unlockRequests;

    constructor(uint256 noticePeriod_) {
        NOTICE_PERIOD = noticePeriod_;
    }

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
            revert TimelockAsyncUnlock__RequestBeforeDepositPeriod(_msgSender(), unlockPeriod, depositWithNoticePeriod);
        }

        uint256 currentWithNoticePeriod = currentPeriod() + NOTICE_PERIOD;
        if (unlockPeriod < currentWithNoticePeriod) {
            revert TimelockAsyncUnlock__RequestBeforeCurrentPeriod(_msgSender(), unlockPeriod, currentWithNoticePeriod);
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

    /// @notice Requests unlocking of `amount`, which will be available after the `unlockPeriod`.
    function requestUnlock(uint256 amount, address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod)
        public
        onlyTokenOwner(tokenOwner)
        validateRequestPeriod(depositPeriod, unlockPeriod)
    {
        // Store unlock request
        _unlockRequests[depositPeriod][tokenOwner] = UnlockItem({
            account: tokenOwner,
            depositPeriod: depositPeriod,
            unlockPeriod: unlockPeriod,
            amount: amount
        });
    }

    /// @notice Unlocks `amount` after the `redeemPeriod`, transferring to `tokenOwner`.
    function unlock(uint256 amount, address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod)
        public
        onlyTokenOwner(tokenOwner)
        validateUnlockPeriod(depositPeriod, unlockPeriod)
    {
        UnlockItem memory unlockRequest = _unlockRequests[depositPeriod][tokenOwner];

        if (amount > unlockRequest.amount) {
            revert ITimelockOpenEnded__ExceededMaxUnlock(tokenOwner, amount, unlockRequest.amount);
        }

        // Process the unlock
        _updateLockAfterUnlock(tokenOwner, depositPeriod, amount);
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public virtual override {
        unlock(amount, account, depositPeriod, currentPeriod());
    }

    /// @notice Process the lock after successful unlocking
    function _updateLockAfterUnlock(address account, uint256 depositPeriod, uint256 amount) internal virtual;

    /// @dev there's no "unlocked" state.  deposits are locked => requested to be unlocked => redeemed
    function unlockedAmount(address, /* account */ uint256 /* depositPeriod */ )
        public
        view
        virtual
        override
        returns (uint256 unlockedAmount_)
    {
        return 0;
    }

    /// @notice Returns the current period.
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }
}
