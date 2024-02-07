//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MaturityVault } from "../../../src/extensions/MaturityVault.sol";

contract MaturityVaultMock is MaturityVault {
    constructor(VaultParams memory params) MaturityVault(params) { }

    modifier withdrawModifier() override {
        _checkVaultMaturity();
        _;
    }

    function toogleMaturityCheck(bool status) public {
        _toogleMaturityCheck(status);
    }
}
