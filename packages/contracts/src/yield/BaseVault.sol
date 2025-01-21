// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Timer } from "@credbull/timelock/Timer.sol";
import { IERC6372 } from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

/**
 * @title BaseVault
 * Vault with the following properties:
 * - Upgradeable - upgradeable contract
 * - Access Control - Role Based Access Control (RBAC)
 * - IERC6372 - clock
 */
contract BaseVault is Initializable, UUPSUpgradeable, AccessControlEnumerableUpgradeable, IERC6372 {
    struct VaultAuth {
        address owner;
        address operator;
        address upgrader;
        address assetManager;
    }

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    error LiquidContinuousMultiTokenVault__InvalidAuthAddress(string authName, address authAddress);

    constructor() {
        _disableInitializers();
    }

    function __BaseVault_init(VaultAuth memory vaultAuth) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _initRole("owner", DEFAULT_ADMIN_ROLE, vaultAuth.owner);
        _initRole("operator", OPERATOR_ROLE, vaultAuth.operator);
        _initRole("upgrader", UPGRADER_ROLE, vaultAuth.upgrader);
        _initRole("assetManager", ASSET_MANAGER_ROLE, vaultAuth.assetManager);
    }

    function _initRole(string memory roleName, bytes32 role, address account) private {
        if (account == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidAuthAddress(roleName, account);
        }

        _grantRole(role, account);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE) { }

    // ===================== IERC6372 Clock =====================

    /// @inheritdoc IERC6372
    function clock() public view returns (uint48 clock_) {
        return Timer.clock();
    }

    /// @inheritdoc IERC6372
    function CLOCK_MODE() public pure returns (string memory) {
        return Timer.CLOCK_MODE();
    }

    // ===================== Utility =====================

    function getVersion() public pure returns (uint256 version) {
        return 2;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
