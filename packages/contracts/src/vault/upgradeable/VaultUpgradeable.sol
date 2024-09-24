//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Credbull Vault
 * @notice The family defining contract, based upon Open Zeppelin's ERC4626 implementation.
 * @dev Uses a Custodian Account to accummulate the deposited Asset.
 */
abstract contract VaultUpgradeable is UUPSUpgradeable, ERC4626Upgradeable, PausableUpgradeable {
    using Math for uint256;

    /// @notice Thrown when attempting to create a Credbull Vault with an invalid Custodian Address.
    error CredbullVault__InvalidCustodianAddress(address);
    /// @notice Thrown when attempting to create a Credbull Vault with a non-addressable Asset IERC20.
    error CredbullVault__InvalidAsset(IERC20);
    error CredbullVault__TransferOutsideEcosystem(address);
    error CredbullVault__InvalidAssetAmount(uint256);
    error CredbullVault__UnsupportedDecimalValue(uint8);

    /// @notice The set of parameters required to create a Credbull Vault instance.
    /// @dev Using from Vault contract
    struct VaultParams {
        IERC20 asset;
        string shareName;
        string shareSymbol;
        address custodian;
    }

    /// @notice Address of the CUSTODIAN to receive the assets on deposit and mint
    address public CUSTODIAN;

    /**
     * @dev The assets deposited to the vault will be sent to CUSTODIAN address so this is
     * separate variable to track the total assets that's been deposited to this vault.
     */
    uint256 public totalAssetDeposited;

    /// @notice The vault decimal which is same as the asset decimal
    uint8 public VAULT_DECIMALS;

    /// @notice Max decimal value supported by the vault
    uint8 public constant MAX_DECIMAL = 18;

    /// @notice Min decimal value supported by vault
    uint8 public constant MIN_DECIMAL = 6;

    /// @notice Modifier to add additional checks on _deposit, the deposit/mint common workflow function.
    modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) virtual {
        _;
    }

    /// @notice Modifier to add additional checks on _withdraw, the withdraw/redeem common workflow function.
    modifier onWithdrawOrRedeem(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        virtual
    {
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override { }

    function initialize(VaultParams memory params) public initializer {
        __UUPSUpgradeable_init();
        __ERC4626_init(params.asset);
        __ERC20_init(params.shareName, params.shareSymbol);

        if (params.custodian == address(0)) {
            revert CredbullVault__InvalidCustodianAddress(params.custodian);
        }
        if (address(params.asset) == address(0)) {
            revert CredbullVault__InvalidAsset(params.asset);
        }

        CUSTODIAN = params.custodian;

        VAULT_DECIMALS = _checkValidDecimalValue(address(params.asset));
    }

    /**
     * @dev - The internal deposit function of ERC4626 overridden to transfer the asset to CUSTODIAN wallet
     * and update the _totalAssetDeposited on deposit/mint
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        virtual
        override
        onDepositOrMint(caller, receiver, assets, shares)
        whenNotPaused
    {
        (, uint256 reminder) = assets.tryMod(10 ** VAULT_DECIMALS);
        if (reminder > 0) {
            revert CredbullVault__InvalidAssetAmount(assets);
        }

        totalAssetDeposited += assets;
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, CUSTODIAN, assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev - The internal withdraw function of ERC4626 overridden to update the _totalAssetDeposited on withdraw/redeem
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
        override
        onWithdrawOrRedeem(caller, receiver, owner, assets, shares)
        whenNotPaused
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        totalAssetDeposited -= assets;

        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice - Returns the total assets deposited into the vault
     * @dev - The function is overridden to return the _totalAssetDeposited value to calculate shares.
     */
    function totalAssets() public view override returns (uint256) {
        return totalAssetDeposited;
    }

    /// @notice Check decimal value of the asset and token used in the vaults.
    //Revert if it's not supported
    function _checkValidDecimalValue(address token) internal view returns (uint8) {
        uint8 decimal = ERC20Upgradeable(token).decimals();

        if (decimal > MAX_DECIMAL || decimal < MIN_DECIMAL) {
            revert CredbullVault__UnsupportedDecimalValue(decimal);
        }

        return decimal;
    }

    /// @notice The share token should not be transferable.
    function transfer(address, /* to */ uint256 /* value */ )
        public
        view
        override(ERC20Upgradeable, IERC20)
        returns (bool)
    {
        revert CredbullVault__TransferOutsideEcosystem(msg.sender);
    }

    /// @notice The share token should not be transferable.
    function transferFrom(address from, address, /* to */ uint256 /* value */ )
        public
        pure
        override(ERC20Upgradeable, IERC20)
        returns (bool)
    {
        revert CredbullVault__TransferOutsideEcosystem(from);
    }

    /// @notice Decimal value of share token is same as asset token
    function decimals() public view override returns (uint8) {
        return VAULT_DECIMALS;
    }

    /// @notice Withdraw any ERC20 tokens sent directly to contract.
    /// This should be implemented by the inherited contract and should be callable only by the admin.
    function _withdrawERC20(address[] calldata _tokens, address _to) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 balance = IERC20(_tokens[i]).balanceOf(address(this));
            SafeERC20.safeTransfer(IERC20(_tokens[i]), _to, balance);
        }
    }
}
