//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MaturityVault } from "@src/vault/MaturityVault.sol";
import { FixedYieldVault } from "@src/vault/FixedYieldVault.sol";

contract MockMaturityVault is MaturityVault {
    constructor(MaturityVaultParameters memory params) MaturityVault(params) { }

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
