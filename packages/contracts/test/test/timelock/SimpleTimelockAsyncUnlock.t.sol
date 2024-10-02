// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";
import { TimerCheats } from "@test/test/timelock/TimerCheats.t.sol";

contract SimpleTimelockAsyncUnlock is TimelockAsyncUnlock, TimerCheats {
    IERC5679Ext1155 public immutable DEPOSITS;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits)
        TimelockAsyncUnlock(noticePeriod_)
        TimerCheats(block.timestamp)
    {
        DEPOSITS = deposits;
    }

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens locked for `owner` at the given `depositPeriod`.
    function lockedAmount(address owner, uint256 depositPeriod) public view override returns (uint256 lockedAmount_) {
        return DEPOSITS.balanceOf(owner, depositPeriod);
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return elapsed24Hours();
    }

    function setCurrentPeriod(uint256 currentPeriod_) public {
        warp24HourPeriods(currentPeriod_);
    }

    function unlock(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) public override {
        super.unlock(owner, depositPeriod, unlockPeriod, amount);

        DEPOSITS.burn(owner, depositPeriod, amount, _emptyBytesArray());
    }

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }
}
