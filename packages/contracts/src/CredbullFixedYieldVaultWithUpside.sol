// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { UpsideVault } from "./vaults/UpsideVault.sol";
import { ICredbull } from "./interface/ICredbull.sol";

contract CredbullFixedYieldVaultWithUpside is UpsideVault {
    constructor(ICredbull.UpsideVaultParams memory params) UpsideVault(params) { }
}
