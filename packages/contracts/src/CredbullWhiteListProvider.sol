// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { WhiteListProvider } from "./provider/whiteList/WhiteListProvider.sol";

/**
 * @title Credbull White List Provider implementation.
 * @author @pasviegas
 * @notice The deployable white list provider contract.
 */
contract CredbullWhiteListProvider is WhiteListProvider {
    constructor(address _owner) WhiteListProvider(_owner) { }
}
