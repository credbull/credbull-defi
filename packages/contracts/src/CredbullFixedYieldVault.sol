//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { FixedYieldVault } from "./vault/FixedYieldVault.sol";

contract CredbullFixedYieldVault is FixedYieldVault {
    constructor(FixedYieldVaultParameters memory params) FixedYieldVault(params) { }
}
