// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IWhiteListProvider {
    function status(address receiver) external view returns (bool);

    function updateStatus(address[] calldata _addresses, bool[] calldata _statuses) external;
}
