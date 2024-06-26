//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

<<<<<<<< HEAD:packages/contracts/test/test/vault/SimpleWindowVault.t.sol
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
========
import { Vault } from "@src/vault/Vault.sol";
import { WindowPlugIn } from "@src/plugin/WindowPlugIn.sol";

contract MockWindowVault is Vault, WindowPlugIn {
    constructor(VaultParameters memory params, WindowPlugInParameters memory windowPlugInParams)
        Vault(params)
        WindowPlugIn(windowPlugInParams)
>>>>>>>> 00739ff (LOADS of re-structuring and renaming into a better structure (for me). This is for review.):packages/contracts/test/test/mock/vault/MockWindowVault.t.sol
    { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsDepositWithinWindow();
        _;
    }

    modifier withdrawModifier(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkIsWithdrawWithinWindow();
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
