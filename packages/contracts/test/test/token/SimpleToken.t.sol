// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OwnableToken } from "@test/test/token/OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token.
 * @dev The Symbol, Name and decimals are hard-coded, so an instance cannot represent anything other than 'SMPL'.
 */
contract SimpleToken is OwnableToken {
    constructor(address owner, uint256 initialSupply) OwnableToken(owner, "Simple Token", "SMPL", 18, initialSupply) { }
}
