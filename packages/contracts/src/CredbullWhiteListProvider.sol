// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { WhiteListProvider } from "./provider/whiteList/WhiteListProvider.sol";

/**
 * @title Credbull White List Provider implementation.
 * @author @pasviegas
 * @notice The deployable white list provider contract.
 */
contract CredbullWhiteListProvider is WhiteListProvider {
    string private constant HASH = "change the checksum";

    constructor(address _owner) WhiteListProvider(_owner) { }

    function hashed() external pure returns (string memory) {
        return HASH;
    }
}
