// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.9;

import "zodiac-delay-modifier/contracts/Delay.sol";

contract TimelockModifier is Delay {
    constructor(
        address _owner,
        address _avatar,
        address _target,
        uint256 _cooldown,
        uint256 _expiration
    ) Delay(_owner, _avatar, _target, _cooldown, _expiration) {}
}
