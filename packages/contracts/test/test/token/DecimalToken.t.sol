// SDPX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { OwnableToken } from "./OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token, with configurable `decimals` value.
 * @dev The Symbol and Name computed based on `_decimals`.
 */
contract DecimalToken is OwnableToken {
    constructor(uint256 initialSupply, uint8 _decimals)
        OwnableToken(
            string.concat("Decimal ", Strings.toString(_decimals), " Token"),
            string.concat("DT", Strings.toString(_decimals)),
            _decimals,
            initialSupply
        )
    { }
}
