// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedYieldVault } from "./FixedYieldVault.sol";

contract UpsideVault is FixedYieldVault {
    using Math for uint256;

    error CredbullVault__InsufficientShareBalance();

    IERC20 public token;
    uint256 public twap = 100_00;
    uint256 public collateralPercentage;

    mapping(address account => uint256) private _balances;
    uint256 public totalCollateralDeposited;

    uint256 private constant MAX_PERCENTAGE = 100_00; //100% upto two decimals
    uint256 private additionalPrecision;

    constructor(VaultParams memory params, IERC20 _token, uint256 _collateralPercentage) FixedYieldVault(params) {
        collateralPercentage = _collateralPercentage;
        token = _token;

        uint8 assetDecimal = _checkValidDecimalValue(address(params.asset));
        uint8 tokenDecimal = _checkValidDecimalValue(address(_token));

        if (tokenDecimal >= assetDecimal) {
            additionalPrecision = 10 ** (tokenDecimal - assetDecimal);
        } else {
            revert CredbullVault__UnsupportedDecimalValue();
        }
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
        internal
        override
        depositModifier(caller, receiver, assets, shares)
    {
        (, uint256 reminder) = assets.tryMod(10 ** VAULT_DECIMALS);
        if (reminder > 0) {
            revert CredbullVault__InvalidAssetAmount();
        }

        uint256 collateral = getCollateralAmount(assets);

        _balances[receiver] += collateral;
        totalCollateralDeposited += collateral;
        totalAssetDeposited += assets;

        if (totalAssetDeposited > maxCap) {
            revert CredbullVault__MaxCapReached();
        }

        SafeERC20.safeTransferFrom(token, _msgSender(), address(this), collateral);
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, custodian, assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
        withdrawModifier(caller, receiver, owner, assets, shares)
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        uint256 collateral = calculateTokenRedemption(shares, owner);

        _balances[owner] -= collateral;
        totalCollateralDeposited -= collateral;
        totalAssetDeposited -= assets;

        SafeERC20.safeTransfer(token, receiver, collateral);

        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function getCollateralAmount(uint256 assets) public view virtual returns (uint256) {
        return
            ((assets * additionalPrecision).mulDiv(collateralPercentage, MAX_PERCENTAGE)).mulDiv(MAX_PERCENTAGE, twap);
    }

    function calculateTokenRedemption(uint256 shares, address account) public view virtual returns (uint256) {
        if (balanceOf(account) < shares) {
            revert CredbullVault__InsufficientShareBalance();
        }

        uint256 vaultPercent = shares.mulDiv(MAX_PERCENTAGE, totalSupply());
        return totalCollateralDeposited.mulDiv(vaultPercent, MAX_PERCENTAGE);
    }

    function setTWAP(uint256 _twap) public onlyRole(OPERATOR_ROLE) {
        twap = _twap;
    }
}
