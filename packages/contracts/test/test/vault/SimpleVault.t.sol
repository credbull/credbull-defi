//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Vault } from "@credbull/vault/Vault.sol";

/**
 * @notice A simple [Vault] realisation for testing purposes.
 */
contract SimpleVault is Vault {
    constructor(Vault.VaultParams memory params) Vault(params) { }

    function withdrawERC20(address[] calldata _tokens, address _to) external {
        _withdrawERC20(_tokens, _to);
    }
}
