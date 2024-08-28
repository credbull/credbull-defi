// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import { ITimelock } from "./ITimelock.s.sol";

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TimelockIERC1155 is ITimelock, ERC1155, ERC1155Supply, Ownable {
    uint256 public lockDuration;
    uint256 public currentTimePeriodsElapsed = 0;

    constructor(address _initialOwner, uint256 _lockDuration) ERC1155("credbull.io/funds/1") Ownable(_initialOwner) {
        lockDuration = _lockDuration;
    }

    // ======================== IERC1155 interface ========================

    function getLockedAmount(address account, uint256 lockReleasePeriod) public view returns (uint256 amountLocked) {
        return balanceOf(account, lockReleasePeriod);
    }

    function lock(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
        _mint(account, lockReleasePeriod, value, "");
    }

    function unlock(address account, uint256 lockReleasePeriod, uint256 value) public onlyOwner {
        if (currentTimePeriodsElapsed < lockReleasePeriod) {
            revert LockDurationNotExpired(currentTimePeriodsElapsed, lockReleasePeriod);
        }

        uint256 lockedBalance = getLockedAmount(account, lockReleasePeriod);
        if (lockedBalance < value) {
            revert InsufficientLockedBalance(lockedBalance, value);
        }

        _burn(account, lockReleasePeriod, value);
    }

    // TODO - choose which to use
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        // You can choose to call one of the base contract's implementations or provide your own
        ERC1155Supply._update(from, to, ids, values);
    }

    function getCurrentTimePeriodsElapsed() public view returns (uint256) {
        return currentTimePeriodsElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }
}
