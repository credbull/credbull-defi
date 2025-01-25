// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockIERC1155 } from "@credbull/timelock/TimelockIERC1155.t.sol";
import { ITimelock } from "@credbull/timelock/ITimelock.sol";
import { TimelockTest } from "@test/src/timelock/TimelockTest.t.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TimelockIERC1155Test is TimelockTest {
    function setUp() public {
        _timelock = _createTimelock(_owner, 2);
    }

    function _toImpl(ITimelock timelock_) internal pure returns (SimpleTimelockIERC1155) {
        // Simulate time passing by setting the current time periods elapsed
        return SimpleTimelockIERC1155(address(timelock_));
    }

    function _rolloverLockDuration(ITimelock timelock_) internal virtual override returns (uint256 lockDuration) {
        return _toImpl(timelock_).lockDuration();
    }

    function _warpToPeriod(ITimelock timelock_, uint256 timePeriod) internal override {
        SimpleTimelockIERC1155 timelock = _toImpl(timelock_);

        uint256 warpToTimeInSeconds = timelock._startTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }

    function _createTimelock(address owner, uint256 lockPeriod)
        public
        returns (SimpleTimelockIERC1155 simpleTimelock)
    {
        SimpleTimelockIERC1155 timeLockImpl = new SimpleTimelockIERC1155();
        SimpleTimelockIERC1155 timeLockProxy = SimpleTimelockIERC1155(
            address(
                new ERC1967Proxy(
                    address(timeLockImpl), abi.encodeWithSelector(timeLockImpl.initialize.selector, owner, lockPeriod)
                )
            )
        );
        return timeLockProxy;
    }
}

contract SimpleTimelockIERC1155 is ITimelock, Initializable, UUPSUpgradeable, TimelockIERC1155, OwnableUpgradeable {
    uint256 public _lockDuration;
    uint256 public _startTimestamp;

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, uint256 lockDuration_) public initializer {
        __TimelockIERC1155_init();
        __Ownable_init(initialOwner);
        _lockDuration = lockDuration_;
        _startTimestamp = block.timestamp;
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override { }

    function lockDuration() public view override returns (uint256 lockDuration_) {
        return _lockDuration;
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return Timer.elapsed24Hours(_startTimestamp);
    }

    /// @notice Locks `amount` of tokens for `account` until `lockReleasePeriod`.
    function lock(address account, uint256 lockReleasePeriod, uint256 amount) public onlyOwner {
        _lockInternal(account, lockReleasePeriod, amount);
    }

    /// @notice Unlocks `amount` of tokens for `account` at `lockReleasePeriod`.
    function unlock(address account, uint256 lockReleasePeriod, uint256 amount) public onlyOwner {
        _unlockInternal(account, lockReleasePeriod, amount);
    }

    /// @notice Rolls over unlocked `amount` of tokens for `account` to a new lock period.
    function rolloverUnlocked(address account, uint256 origLockReleasePeriod, uint256 amount) public onlyOwner {
        _rolloverUnlockedInternal(account, origLockReleasePeriod, amount);
    }

    // multi-inheritence below

    /// @inheritdoc ITimelock
    function lockedAmount(address account, uint256 lockReleasePeriod)
        public
        view
        override(ITimelock, TimelockIERC1155)
        returns (uint256 lockedAmount_)
    {
        return TimelockIERC1155.lockedAmount(account, lockReleasePeriod);
    }

    /// @inheritdoc ITimelock
    function maxUnlock(address account, uint256 lockReleasePeriod)
        public
        view
        override(ITimelock, TimelockIERC1155)
        returns (uint256 unlockableAmount_)
    {
        return TimelockIERC1155.maxUnlock(account, lockReleasePeriod);
    }

    /// @inheritdoc ITimelock
    function lockPeriods(address account, uint256 fromPeriod, uint256 toPeriod, uint256 increment)
        public
        view
        override(ITimelock, TimelockIERC1155)
        returns (uint256[] memory lockedPeriods_, uint256[] memory lockedAmounts_)
    {
        return TimelockIERC1155.lockPeriods(account, fromPeriod, toPeriod, increment);
    }
}
