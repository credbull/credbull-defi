//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Vault } from "@src/vault/Vault.sol";
import { WhitelistPlugIn } from "@src/plugin/WhitelistPlugIn.sol";

contract MockWhitelistVault is Vault, WhitelistPlugIn {
    constructor(VaultParameters memory params, WhitelistPlugInParameters memory whitelistPlugInParams)
        Vault(params)
        WhitelistPlugIn(whitelistPlugInParams)
    { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhitelisted(receiver, assets);
        _;
    }

    function toggleWhitelistCheck(bool status) public {
        _toggleWhitelistCheck(status);
    }
}
