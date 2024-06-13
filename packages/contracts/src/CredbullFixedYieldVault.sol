//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { FixedYieldVault } from "./vaults/FixedYieldVault.sol";

contract CredbullFixedYieldVault is FixedYieldVault {
    constructor(FixedYieldVaultParams memory params) FixedYieldVault(params) { }
}
