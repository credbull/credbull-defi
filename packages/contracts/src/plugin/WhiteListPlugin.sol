//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IWhiteListProvider } from "../provider/whiteList/IWhiteListProvider.sol";

/// @notice - A Plugin to handle whiteListing
abstract contract WhiteListPlugin {
    /// @notice If an invalid `IWhiteListProvider` Address is provided.
    error CredbullVault__InvalidWhiteListProviderAddress(address);
    /// @notice Error to revert if the address is not whiteListed
    error CredbullVault__NotWhiteListed(address, uint256);

    /// @notice Event emitted when the whiteList check is updated
    event WhiteListCheckUpdated(bool indexed checkWhiteList);

    /// @notice - Params for the WhiteList Plugin
    struct WhiteListPluginParams {
        address whiteListProvider;
        uint256 depositThresholdForWhiteListing;
    }

    /// @notice - Address of the White List Provider.
    IWhiteListProvider public immutable WHITELIST_PROVIDER;

    /// @notice - Flag to check for whiteList
    bool public checkWhiteList;

    /// @notice - Deposit threshold amount to check for whiteListing
    uint256 public immutable DEPOSIT_THRESHOLD_FOR_WHITE_LISTING;

    constructor(WhiteListPluginParams memory params) {
        if (params.whiteListProvider == address(0)) {
            revert CredbullVault__InvalidWhiteListProviderAddress(params.whiteListProvider);
        }

        WHITELIST_PROVIDER = IWhiteListProvider(params.whiteListProvider);
        checkWhiteList = true; // Set the check to true by default
        DEPOSIT_THRESHOLD_FOR_WHITE_LISTING = params.depositThresholdForWhiteListing;
    }

    /// @notice - Function to check for whiteListed address
    function _checkIsWhiteListed(address receiver, uint256 amount) internal view virtual {
        if (checkWhiteList && amount >= DEPOSIT_THRESHOLD_FOR_WHITE_LISTING && !WHITELIST_PROVIDER.status(receiver)) {
            revert CredbullVault__NotWhiteListed(receiver, amount);
        }
    }

    /// @notice - Function to toggle check for whiteListed address
    function _toggleWhiteListCheck() internal virtual {
        checkWhiteList = !checkWhiteList;
        emit WhiteListCheckUpdated(checkWhiteList);
    }
}
