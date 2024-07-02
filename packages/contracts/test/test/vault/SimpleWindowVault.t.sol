//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Vault } from "@credbull/vault/Vault.sol";
import { WindowPlugin } from "@credbull/plugin/WindowPlugin.sol";

/**
 * @notice A simple [Vault] with [WindowPlugin] realisation, for testing purposes.
 * @dev It could be called `WindowVault` as there is no name clash, but stuck with the naming convention.
 */
contract SimpleWindowVault is Vault, WindowPlugin {
    constructor(VaultParams memory params, WindowPluginParams memory windowPluginParams)
        Vault(params)
        WindowPlugin(windowPluginParams)
    { }

    modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsDepositWithinWindow();
        _;
    }

    modifier onWithdrawOrRedeem(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkIsRedeemWithinWindow();
        _;
    }

    function updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _withdrawOpen, uint256 _withdrawClose)
        public
    {
        _updateWindow(_depositOpen, _depositClose, _withdrawOpen, _withdrawClose);
    }

    function toggleWindowCheck(bool status) public {
        _toggleWindowCheck(status);
    }
}
