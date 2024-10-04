//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { FixedYieldVault } from "./vault/FixedYieldVault.sol";

contract CredbullFixedYieldVault is FixedYieldVault {
    constructor(FixedYieldVaultParams memory params) FixedYieldVault(params) { }
}
