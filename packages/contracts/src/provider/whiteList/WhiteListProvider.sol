// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IWhiteListProvider } from "./IWhiteListProvider.sol";

contract WhiteListProvider is IWhiteListProvider, Ownable {
    error LengthMismatch();

    /**
     * @notice - Track whiteListed addresses
     */
    mapping(address => bool) public isWhiteListed;

    constructor(address _owner) Ownable(_owner) { }

    function status(address receiver) public view override returns (bool) {
        return isWhiteListed[receiver];
    }

    /**
     * @notice - Method to update the whiteList status of an address called only by the owner.
     *
     * @param _addresses - List of addresses value
     * @param _statuses - List of statuses to update
     */
    function updateStatus(address[] calldata _addresses, bool[] calldata _statuses) external override onlyOwner {
        if (_addresses.length != _statuses.length) revert LengthMismatch();

        uint256 length = _addresses.length;

        for (uint256 i; i < length;) {
            if (_addresses[i] == address(0)) continue;
            isWhiteListed[_addresses[i]] = _statuses[i];

            unchecked {
                ++i;
            }
        }
    }
}
