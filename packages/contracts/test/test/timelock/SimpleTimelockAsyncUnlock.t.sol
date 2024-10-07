// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SimpleTimelockAsyncUnlock is Initializable, UUPSUpgradeable, TimelockAsyncUnlock {
    IERC5679Ext1155 public _deposits;
    uint256 public _currentPeriod;

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override { }

    function initialize(uint256 noticePeriod_, IERC5679Ext1155 deposits) public initializer {
        __TimelockAsyncUnlock_init(noticePeriod_);
        _deposits = deposits;
    }

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        _deposits.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens locked for `owner` at the given `depositPeriod`.
    function lockedAmount(address owner, uint256 depositPeriod) public view override returns (uint256 lockedAmount_) {
        return _deposits.balanceOf(owner, depositPeriod);
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return _currentPeriod;
    }

    function setCurrentPeriod(uint256 currentPeriod_) public {
        _currentPeriod = currentPeriod_;
    }

    function unlock(address owner, uint256 unlockPeriod)
        public
        override
        returns (uint256[] memory depositPeriods, uint256[] memory amounts)
    {
        (depositPeriods, amounts) = super.unlock(owner, unlockPeriod);

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            _deposits.burn(owner, depositPeriods[i], amounts[i], _emptyBytesArray());
        }
    }

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }
}
