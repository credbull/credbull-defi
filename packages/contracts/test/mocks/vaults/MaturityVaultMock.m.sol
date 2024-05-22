//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MaturityVault } from "../../../src/extensions/MaturityVault.sol";
import { ICredbull } from "../../../src/interface/ICredbull.sol";

contract MaturityVaultMock is MaturityVault {
    constructor(ICredbull.FixedYieldVaultParams memory params) MaturityVault(params) { }

    modifier withdrawModifier(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkVaultMaturity();
        _;
    }

    function toogleMaturityCheck(bool status) public {
        _toggleMaturityCheck(status);
    }
}
