//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Vault } from "@credbull/vault/Vault.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";

/**
 * @notice A simple [Vault] with [WhiteListPlugin] realisation, for testing purposes.
 * @dev It could be called `WhiteListVault` as there is no name clash, but stuck with the naming convention.
 */
contract SimpleWhiteListVault is Vault, WhiteListPlugin {
    constructor(VaultParams memory params, WhiteListPluginParams memory whiteListPluginParams)
        Vault(params)
        WhiteListPlugin(whiteListPluginParams)
    { }

    modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhiteListed(receiver, assets);
        _;
    }

    function toggleWhiteListCheck(bool status) public {
        _toggleWhiteListCheck(status);
    }
}
