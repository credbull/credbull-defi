//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { MaxCapPlugin } from "@credbull/plugin/MaxCapPlugin.sol";
import { Vault } from "@credbull/vault/Vault.sol";

/**
 * @notice A simple [Vault] with [MaxCapPlugin] realisation, for testing purposes.
 * @dev It could be called `MaxCapVault` as there is no name clash, but stuck with the naming convention.
 */
contract SimpleMaxCapVault is Vault, MaxCapPlugin {
    constructor(VaultParams memory params, MaxCapPluginParams memory maxCapPluginParams)
        Vault(params)
        MaxCapPlugin(maxCapPluginParams)
    { }

    modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkMaxCap(totalAssetDeposited + assets);
        _;
    }

    function toggleMaxCapCheck(bool status) public {
        _toggleMaxCapCheck(status);
    }

    function updateMaxCap(uint256 _value) public {
        _updateMaxCap(_value);
    }
}
