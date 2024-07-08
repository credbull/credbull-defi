//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { MaturityVault } from "./MaturityVault.sol";
import { WhiteListPlugin } from "../plugin/WhiteListPlugin.sol";
import { WindowPlugin } from "../plugin/WindowPlugin.sol";
import { MaxCapPlugin } from "../plugin/MaxCapPlugin.sol";

contract FixedYieldVault is MaturityVault, WhiteListPlugin, WindowPlugin, MaxCapPlugin, AccessControl {
    using Math for uint256;

    /// @notice - Hash of operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct ContractRoles {
        address owner;
        address operator;
        address custodian;
    }

    struct FixedYieldVaultParams {
        MaturityVaultParams maturityVault;
        ContractRoles roles;
        WindowPluginParams windowPlugin;
        WhiteListPluginParams whiteListPlugin;
        MaxCapPluginParams maxCapPlugin;
        uint256 promisedYield;
    }

    /// @dev The fixed yield value in percentage(100) that's promised to the users on deposit.
    uint256 private _fixedYield;

    constructor(FixedYieldVaultParams memory params)
        MaturityVault(params.maturityVault)
        WhiteListPlugin(params.whiteListPlugin)
        WindowPlugin(params.windowPlugin)
        MaxCapPlugin(params.maxCapPlugin)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, params.roles.owner);
        _grantRole(OPERATOR_ROLE, params.roles.operator);

        _fixedYield = params.promisedYield;
    }

    /// @dev - Overridden deposit modifer
    /// Should check for whiteListed address
    /// Should check for deposit window
    /// Should check for max cap
    modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhiteListed(receiver, assets + convertToAssets(balanceOf(receiver)));
        _checkIsDepositWithinWindow();
        _checkMaxCap(totalAssetDeposited + assets);
        _;
    }

    /// @dev - Overridden withdraw modifier
    /// Should check for withdraw window
    /// Should check for maturity
    modifier onWithdrawOrRedeem(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkIsRedeemWithinWindow();
        _checkVaultMaturity();
        _;
    }

    // @notice - Returns expected assets on maturity
    function expectedAssetsOnMaturity() public view override returns (uint256) {
        return totalAssetDeposited.mulDiv(100 + _fixedYield, 100);
    }

    /// @notice Mature the vault
    function mature() public override onlyRole(OPERATOR_ROLE) {
        _mature();
    }

    /// @notice Toggle check for maturity
    function toggleMaturityCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleMaturityCheck(status);
    }

    /// @notice Toggle check for whiteList
    function toggleWhiteListCheck(bool status) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _toggleWhiteListCheck(status);
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
