// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IKYCProvider } from "./interface/IKYCProvider.sol";

contract CredbullKYCProvider is IKYCProvider, Ownable {
    error LengthMismatch();

    /**
     * @notice - Track whitelisted addresses
     */
    mapping(address => bool) public isWhitelisted;

    constructor(address _owner) Ownable(_owner) { }

    function status(address receiver) public view override returns (bool) {
        return isWhitelisted[receiver];
    }

    /**
     * @notice - Method to update the whitelist status of an address called only by the owner.
     *
     * @param _addresses - List of addresses value
     * @param _statuses - List of statuses to update
     */
    function updateStatus(address[] calldata _addresses, bool[] calldata _statuses) external override onlyOwner {
        if (_addresses.length != _statuses.length) revert LengthMismatch();

        uint256 length = _addresses.length;

        for (uint256 i; i < length;) {
            isWhitelisted[_addresses[i]] = _statuses[i];

            unchecked {
                ++i;
            }
        }
    }
}
