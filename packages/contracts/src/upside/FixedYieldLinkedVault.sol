//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { WhitelistPlugIn } from "../plugins/WhitelistPlugIn.sol";
import { WindowPlugIn } from "../plugins/WindowPlugIn.sol";
import { ParentLinkPlugIn } from "../plugins/ParentLinkPlugIn.sol";
import { CallerReceiverVault } from "../extensions/CallerReceiverVault.sol";

contract FixedYieldLinkedVault is
    CallerReceiverVault,
    WhitelistPlugIn,
    WindowPlugIn,
    ParentLinkPlugIn,
    AccessControl
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(VaultParams memory params, address _parentLink)
        CallerReceiverVault(params)
        ParentLinkPlugIn(_parentLink)
        WhitelistPlugIn(params.kycProvider)
        WindowPlugIn(params.depositOpensAt, params.depositClosesAt, params.redemptionOpensAt, params.redemptionClosesAt)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, params.owner);
        _grantRole(OPERATOR_ROLE, params.operator);
    }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkParentLink(_msgSender());
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
