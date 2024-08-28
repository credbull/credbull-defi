// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";
import { TimelockIERC1155 } from "../timelock/TimelockIERC1155.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract TimelockInterestVault is TimelockIERC1155, SimpleInterestVault {
    constructor(address initialOwner, IERC20 asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
        TimelockIERC1155(initialOwner, tenor)
        SimpleInterestVault(asset, interestRatePercentage, frequency, tenor)
    { }

    // we want the supply of the ERC20 token - not the locks
    function totalSupply() public view virtual override(ERC1155Supply, IERC20, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    function deposit(uint256 assets, address receiver) public override(SimpleInterestVault) returns (uint256 shares) {
        shares = SimpleInterestVault.deposit(assets, receiver);

        // Call the internal _lock function instead, which handles the locking logic
        _lockInternal(receiver, currentTimePeriodsElapsed + lockDuration, shares);

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override(SimpleInterestVault)
        returns (uint256)
    {
        // First, unlock the shares if possible
        _unlockInternal(owner, currentTimePeriodsElapsed, shares);

        // Then, redeem the shares for the corresponding amount of assets
        return SimpleInterestVault.redeem(shares, receiver, owner);
    }

    // TODO - ugly, storing state at the parent that means pretty much the same thing
    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public override {
        super.setCurrentPeriod(_currentTimePeriodsElapsed);
        super.setCurrentTimePeriodsElapsed(_currentTimePeriodsElapsed);
    }

    // TODO - ugly, storing state at the parent that means pretty much the same thing
    function setCurrentPeriod(uint256 _currentPeriod) public override {
        super.setCurrentPeriod(_currentPeriod);
        super.setCurrentTimePeriodsElapsed(_currentPeriod);
    }
}
