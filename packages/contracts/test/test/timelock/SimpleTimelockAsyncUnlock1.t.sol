// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock1 } from "@credbull/timelock/TimelockAsyncUnlock1.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";
import { TimerCheats } from "@test/test/timelock/TimerCheats.t.sol";

contract SimpleTimelockAsyncUnlock1 is TimelockAsyncUnlock1, TimerCheats {
    IERC5679Ext1155 public immutable DEPOSITS;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits)
        TimelockAsyncUnlock1(noticePeriod_)
        TimerCheats(block.timestamp)
    {
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
