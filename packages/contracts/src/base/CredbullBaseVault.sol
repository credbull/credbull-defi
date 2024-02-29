//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { ICredbull } from "../interface/ICredbull.sol";

abstract contract CredbullBaseVault is ICredbull, ERC4626 {
    using Math for uint256;

    error CredbullVault__TransferOutsideEcosystem();
    error CredbullVault__InvalidAssetAmount(uint256);
    error CredbullVault__UnsupportedDecimalValue(uint8);

    /// @notice Address of the CUSTODIAN to receive the assets on deposit and mint
    address public immutable CUSTODIAN;

    /**
     * @dev
     * The assets deposited to the vault will be sent to CUSTODIAN address so this is
     * separate variable to track the total assets that's been deposited to this vault.
     */
    uint256 public totalAssetDeposited;

    /// @notice The vault decimal which is same as the asset decimal
    uint8 public immutable VAULT_DECIMALS;

    /// @notice Max decimal value supported by the vault
    uint8 public constant MAX_DECIMAL = 18;

    /// @notice Min decimal value supported by vault
    uint8 public constant MIN_DECIMAL = 6;

    /// @notice Modifier to add additional checks on deposit
    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) virtual {
        _;
    }

    /// @notice Modifier to add additional checks on withdraw
    modifier withdrawModifier(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        virtual
    {
        _;
    }

    /**
     *
     * @param params - Vault parameters
     */
    constructor(VaultParams memory params) ERC4626(params.asset) ERC20(params.shareName, params.shareSymbol) {
        if (params.custodian == address(0) || address(params.asset) == address(0)) {
            revert ZeroAddress();
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
        depositModifier(caller, receiver, assets, shares)
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
        withdrawModifier(caller, receiver, owner, assets, shares)
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
        uint8 decimal = ERC20(token).decimals();

        if (decimal > MAX_DECIMAL || decimal < MIN_DECIMAL) {
            revert CredbullVault__UnsupportedDecimalValue(decimal);
        }

        return decimal;
    }

    /// @notice The share token should be soul bound. Should be transferable only to vault to receive assets back
    function transfer(address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        if (to != address(this)) revert CredbullVault__TransferOutsideEcosystem();
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @notice The share token should be soul bound. Should be transferable only to vault to receive assets back
    function transferFrom(address from, address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        if (to != address(this)) revert CredbullVault__TransferOutsideEcosystem();
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /// @notice Decimal value of share token is same as asset token
    function decimals() public view override returns (uint8) {
        return VAULT_DECIMALS;
    }
}
