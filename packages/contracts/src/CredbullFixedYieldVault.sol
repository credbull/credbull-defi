//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { FixedYieldVault } from "./vaults/FixedYieldVault.sol";
import { ICredbull } from "./interface/ICredbull.sol";

contract CredbullFixedYieldVault is FixedYieldVault {
    constructor(ICredbull.FixedYieldVaultParams memory params) FixedYieldVault(params) { }
}
