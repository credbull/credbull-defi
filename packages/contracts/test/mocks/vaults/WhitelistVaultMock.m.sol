//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { WhitelistPlugIn } from "../../../src/plugins/WhitelistPlugIn.sol";

contract WhitelistVaultMock is CredbullBaseVault, WhitelistPlugIn {
    constructor(VaultParams memory params) CredbullBaseVault(params) WhitelistPlugIn(params.kycProvider) { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhitelisted(receiver);
        _;
    }

    function toggleWhitelistCheck(bool status) public {
        _toggleWhitelistCheck(status);
    }
}
