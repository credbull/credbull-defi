//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MaxCapPlugIn } from "@src/plugin/MaxCapPlugIn.sol";
import { Vault } from "@src/vault/Vault.sol";

contract MockMaxCapVault is Vault, MaxCapPlugIn {
    constructor(VaultParameters memory params, MaxCapPlugInParameters memory maxCapPlugInParams)
        Vault(params)
        MaxCapPlugIn(maxCapPlugInParams)
    { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
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
