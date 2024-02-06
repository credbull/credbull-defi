//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { ICredbull } from "../../interface/ICredbull.sol";

abstract contract CredbullBaseVault is ICredbull, ERC4626 {
    using Math for uint256;

    //Address of the custodian to receive the assets on deposit and mint
    address public custodian;

    /**
     * @dev
     * The assets deposited to the vault will be sent to custodian address so this is
     * separate variable to track the total assets that's been deposited to this vault.
     */
    uint256 public totalAssetDeposited;

    modifier depositModifier(address receiver) virtual {
        _;
    }

    modifier withdrawModifier() virtual {
        _;
    }

    constructor(VaultParams memory params) ERC4626(params.asset) ERC20(params.shareName, params.shareSymbol) {
        custodian = params.custodian;
    }

    /**
     * @dev - The internal deposit function of ERC4626 overridden to transfer the asset to custodian wallet
     * and update the _totalAssetDeposited on deposit/mint
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        override
        depositModifier(receiver)
    {
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, custodian, assets);
        totalAssetDeposited += assets;

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev - The internal withdraw function of ERC4626 overridden to update the _totalAssetDeposited on withdraw/redeem
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
        withdrawModifier
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
        totalAssetDeposited -= assets;

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice - Returns the total assets deposited into the vault
     * @dev - The function is overridden to return the _totalAssetDeposited value to calculate shares.
     */
    function totalAssets() public view override returns (uint256) {
        return totalAssetDeposited;
    }
}
