//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { MaturityVault } from "../extensions/MaturityVault.sol";
import { WhitelistPlugIn } from "../plugins/WhitelistPlugIn.sol";
import { WindowPlugIn } from "../plugins/WindowPlugIn.sol";
import { MaxCapPlugIn } from "../plugins/MaxCapPlug.sol";

/// @notice - A Fixed yield vault
contract FixedYieldVault is MaturityVault, WhitelistPlugIn, WindowPlugIn, MaxCapPlugIn, AccessControl {
    /// @notice - Hash of operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice - Struct to hold the parameters for FixedYieldVault
    struct FixedYieldVaultParams {
        MaturityVaultParams maturityVaultParams;
        ContractRoles contractRoles;
        WindowVaultParams windowVaultParams;
        KycParams kycParams;
        MaxCapParams maxCapParams;
    }

    constructor(FixedYieldVaultParams memory params)
        MaturityVault(params.maturityVaultParams)
        WhitelistPlugIn(params.kycParams.kycProvider, params.kycParams.depositThresholdForWhitelisting)
        MaxCapPlugIn(params.maxCapParams.maxCap)
        WindowPlugIn(
            params.windowVaultParams.depositWindow.opensAt,
            params.windowVaultParams.depositWindow.closesAt,
            params.windowVaultParams.matureWindow.opensAt,
            params.windowVaultParams.matureWindow.closesAt
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, params.contractRoles.owner);
        _grantRole(OPERATOR_ROLE, params.contractRoles.operator);
    }

    /// @dev - Overridden deposit modifer
    /// Should check for whitelisted address
    /// Should check for deposit window
    /// Should check for max cap
    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhitelisted(receiver, assets + convertToAssets(balanceOf(receiver)));
        _checkIsDepositWithinWindow();
        _checkMaxCap(totalAssetDeposited + assets);
        _;
    }

    /// @dev - Overridden withdraw modifier
    /// Should check for withdraw window
    /// Should check for maturity
    modifier withdrawModifier(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkIsWithdrawWithinWindow();
        _checkVaultMaturity();
        _;
    }

    /// @notice Mature the vault
    function mature() public override onlyRole(OPERATOR_ROLE) {
        _mature();
    }

    /// @notice Toggle check for maturity
    function toggleMaturityCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleMaturityCheck(status);
    }

    /// @notice Toggle check for whitelist
    function toggleWhitelistCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleWhitelistCheck(status);
    }

    /// @notice Toggle check for window
    function toggleWindowCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleWindowCheck(status);
    }

    /// @notice Toggle check for max cap
    function toggleMaxCapCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleMaxCapCheck(status);
    }

    /// @notice Update max cap value
    function updateMaxCap(uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateMaxCap(_value);
    }

    /// @notice Update all window timestamp
    function updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _withdrawOpen, uint256 _withdrawClose)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _updateWindow(_depositOpen, _depositClose, _withdrawOpen, _withdrawClose);
    }

    /// @notice Pause the vault
    function pauseVault() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause the vault
    function unpauseVault() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdrawERC20(address[] calldata _tokens) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdrawERC20(_tokens, msg.sender);
    }
}
