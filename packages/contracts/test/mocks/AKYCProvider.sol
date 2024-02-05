// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract AKYCProvider {
    function status(address receiver) public view virtual returns (bool);

    function updateStatus(address[] calldata _addresses, bool[] calldata _statuses) external virtual;
}
