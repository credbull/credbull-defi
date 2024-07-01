// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { OwnableToken } from "./OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token, used to mimic USDC in tests.
 * @dev The Symbol, Name and decimals are hard-coded, so an instance cannot represent anything other than 'sUSDC'.
 */
contract SimpleUSDC is OwnableToken {
    constructor(uint256 initialSupply) OwnableToken("Simple USDC", "sUSDC", 6, initialSupply) { }
}
