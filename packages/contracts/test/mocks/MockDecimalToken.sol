// SDPX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MockToken } from "./MockToken.sol";

contract MockDecimalToken is MockToken {
    uint8 tokenDecimals;

    constructor(uint256 initialSupply, uint8 _decimals) MockToken(initialSupply) {
        tokenDecimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }
}
