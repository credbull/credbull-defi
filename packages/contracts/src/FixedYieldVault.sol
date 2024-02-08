//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { WhitelistPlugIn } from "./plugins/WhitelistPlugIn.sol";
import { WindowPlugIn } from "./plugins/WindowPlugIn.sol";
import { MaturityVault } from "./extensions/MaturityVault.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract FixedYieldVault is MaturityVault, WhitelistPlugIn, WindowPlugIn, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(VaultParams memory params)
        MaturityVault(params)
        WhitelistPlugIn(params.kycProvider)
        WindowPlugIn(params.depositOpensAt, params.depositClosesAt, params.redemptionOpensAt, params.redemptionClosesAt)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, params.owner);
        _grantRole(OPERATOR_ROLE, params.operator);
    }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhitelisted(receiver);
        _checkIsDepositWithinWindow();
        _;
    }

    modifier withdrawModifier(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkIsWithdrawWithinWindow();
        _checkVaultMaturity();
        _;
    }

    function mature() public override onlyRole(OPERATOR_ROLE) {
        _mature();
    }

    function toggleMaturityCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleMaturityCheck(status);
    }

    function toggleWhitelistCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleWhitelistCheck(status);
    }

    function toggleWindowCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleWindowCheck(status);
    }
}