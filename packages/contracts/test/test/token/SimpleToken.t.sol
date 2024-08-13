// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OwnableToken } from "./OwnableToken.t.sol";

/**
 * @notice A simple [ERC20] Token.
 * @dev The Symbol, Name and decimals are hard-coded, so an instance cannot represent anything other than 'SMPL'.
 */
contract SimpleToken is OwnableToken {
    string private constant HASH = "change the checksum";

    constructor(uint256 initialSupply) OwnableToken("Simple Token", "SMPL", 18, initialSupply) { }

    function hashed() external pure returns (string memory) {
        return HASH;
    }
}
