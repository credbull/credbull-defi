//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";

contract CredbullBaseVaultMock is CredbullBaseVault {
    constructor(VaultParams memory params) CredbullBaseVault(params) { }
}
