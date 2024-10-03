// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";
import { TimerCheats } from "@test/test/timelock/TimerCheats.t.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SimpleTimelockAsyncUnlock is Initializable, UUPSUpgradeable, TimelockAsyncUnlock, TimerCheats {
    IERC5679Ext1155 public DEPOSITS;

    constructor() { }

    function _authorizeUpgrade(address newImplementation) internal virtual override { }

    function initialize(uint256 noticePeriod_, IERC5679Ext1155 deposits) public initializer {
        __TimerCheats__init(block.timestamp);
        __TimelockAsyncUnlock_init(noticePeriod_);
        DEPOSITS = deposits;
    }

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function lockedAmount(address account, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 lockedAmount_)
    {
        return DEPOSITS.balanceOf(account, depositPeriod);
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return elapsed24Hours();
    }

    function setCurrentPeriod(uint256 currentPeriod_) public {
        warp24HourPeriods(currentPeriod_);
    }

    function _finalizeUnlock(address account, uint256 depositPeriod, uint256, /* unlockPeriod */ uint256 amount)
        internal
        virtual
        override
    {
        DEPOSITS.burn(account, depositPeriod, amount, _emptyBytesArray());
    }
}
