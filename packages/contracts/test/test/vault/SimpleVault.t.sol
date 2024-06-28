//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Vault } from "@credbull/vault/Vault.sol";

/**
 * @notice A simple [Vault] realisation for testing purposes.
 */
contract SimpleVault is Vault {
    constructor(Vault.VaultParams memory params) Vault(params) { }
}
