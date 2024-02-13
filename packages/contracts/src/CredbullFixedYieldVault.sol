//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { FixedYieldVault } from "./vaults/FixedYieldVault.sol";

contract CredbullFixedYieldVault is FixedYieldVault {
    constructor(VaultParams memory params) FixedYieldVault(params) { }
}
