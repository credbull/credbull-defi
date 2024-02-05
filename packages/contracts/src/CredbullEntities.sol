// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract CredbullEntities {
    address public custodian;
    address public kycProvider;
    address public treasury;
    address public activityReward;

    constructor(address _custodian, address _kycProvider, address _treasury, address _activityReward) {
        custodian = _custodian;
        kycProvider = _kycProvider;
        treasury = _treasury;
        activityReward = _activityReward;
    }
}
