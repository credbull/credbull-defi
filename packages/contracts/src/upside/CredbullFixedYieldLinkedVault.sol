//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { FixedYieldLinkedVault } from "./FixedYieldLinkedVault.sol";

contract CredbullFixedYieldLinkedVault is FixedYieldLinkedVault {
    constructor(VaultParams memory params) FixedYieldLinkedVault(params) { }
}
