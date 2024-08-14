// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OwnableToken } from "./OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token, used to mimic USDC in tests.
 * @dev The Symbol, Name and decimals are hard-coded, so an instance cannot represent anything other than 'sUSDC'.
 */
contract SimpleUSDC is OwnableToken {
    string private constant HASH = "change the checksum again";

    constructor(uint256 initialSupply) OwnableToken("Simple USDC", "sUSDC", 6, initialSupply) { }

    function hashed() external pure returns (string memory) {
        return HASH;
    }
}
