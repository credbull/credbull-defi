// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import "zodiac-modifier-delay/test/TestAvatar.sol";

contract MockSafe is TestAvatar {

    function enableModule(address _module) external {
        module = _module;
    }

    function disableModule(address, address) external {
        module = address(0);
    }
}
