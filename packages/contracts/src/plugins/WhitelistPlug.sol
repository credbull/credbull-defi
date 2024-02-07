//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { AKYCProvider } from "../../test/mocks/MockKYCProvider.sol";

abstract contract WhitelistPlugIn {
    //Error to revert if the address is not whitelisted
    error CredbullVault__NotAWhitelistedAddress();

    //Mock kyc provider
    AKYCProvider public kycProvider;

    bool public checkWhitelist;

    constructor(address _kycProvider) {
        kycProvider = AKYCProvider(_kycProvider);
        checkWhitelist = true;
    }

    function _checkIsWhitelisted(address receiver) internal view virtual {
        if (checkWhitelist && !kycProvider.status(receiver)) {
            revert CredbullVault__NotAWhitelistedAddress();
        }
    }

    function _toggleWhitelistCheck(bool status) internal virtual {
        checkWhitelist = status;
    }
}
