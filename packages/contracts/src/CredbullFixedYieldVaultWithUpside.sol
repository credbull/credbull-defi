// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { UpsideVault } from "./vault/UpsideVault.sol";

contract CredbullFixedYieldVaultWithUpside is UpsideVault {
    constructor(CredbullFixedYieldVaultWithUpside.UpsideVaultParams memory params) UpsideVault(params) { }
}
