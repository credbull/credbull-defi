//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MaturityVault } from "../../../src/extensions/MaturityVault.sol";
import { FixedYieldVault } from "../../../src/vaults/FixedYieldVault.sol";
import { MaturityVault } from "../../../src/extensions/MaturityVault.sol";

contract MaturityVaultMock is MaturityVault {
    constructor(MaturityVault.MaturityVaultParams memory params) MaturityVault(params) { }

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
