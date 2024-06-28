//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MaturityVault } from "@credbull/vault/MaturityVault.sol";

/**
 * @notice A simple [MaturityVault] realisation for testing purposes.
 */
contract SimpleMaturityVault is MaturityVault {
    constructor(MaturityVaultParams memory params) MaturityVault(params) { }

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
