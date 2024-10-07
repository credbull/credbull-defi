// SDPX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { OwnableToken } from "./OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token, with configurable `decimals` value.
 * @dev The Symbol and Name computed based on `_decimals`.
 */
contract DecimalToken is OwnableToken {
    constructor(address owner, uint256 initialSupply, uint8 _decimals)
        OwnableToken(
            owner,
            string.concat("Decimal ", Strings.toString(_decimals), " Token"),
            string.concat("DT", Strings.toString(_decimals)),
            _decimals,
            initialSupply
        )
    { }
}
