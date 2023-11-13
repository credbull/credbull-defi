// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {TestAvatar} from "zodiac/test/TestAvatar.sol";

contract MockSafe is TestAvatar {
    function exec(
        address payable to,
        uint256 value,
        bytes calldata data
    ) external {
        bool success;
        bytes memory response;
        (success, response) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(response, 0x20), mload(response))
            }
        }
    }
}
