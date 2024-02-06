//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/v2/base/CredbullBaseVault.sol";
import { WhitelistPlugIn } from "../../../src/v2/plugins/WhitelistPlug.sol";

contract WhitelistVaultMock is CredbullBaseVault, WhitelistPlugIn {
    constructor(VaultParams memory params) CredbullBaseVault(params) WhitelistPlugIn(params.kycProvider) { }

    modifier depositModifier(address receiver) override {
        _checkIsWhitelisted(receiver);
        _;
    }

    function toggleWhitelistCheck(bool status) public {
        _toggleWhitelistCheck(status);
    }
}
