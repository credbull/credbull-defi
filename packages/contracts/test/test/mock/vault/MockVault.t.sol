//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Vault } from "@src/vault/Vault.sol";

contract MockVault is Vault {
    constructor(Vault.VaultParameters memory params) Vault(params) { }
}
