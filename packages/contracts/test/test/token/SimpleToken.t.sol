// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { OwnableToken } from "./OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token.
 * @dev The Symbol, Name and decimals are hard-coded, so an instance cannot represent anything other than 'SMPL'.
 */
contract SimpleToken is OwnableToken {
    constructor(uint256 initialSupply) OwnableToken("Simple Token", "SMPL", 18, initialSupply) { }
}
