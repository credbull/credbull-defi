// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { UpsideVault } from "./vaults/UpsideVault.sol";

contract CredbullFixedYieldVaultWithUpside is UpsideVault {
    constructor(UpsideVault.UpsideVaultParams memory params) UpsideVault(params) { }
}
