// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/multitokenvault/IMultiTokenVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract MultiTokenVault is IMultiTokenVault, ERC1155 {
    using SafeERC20 for IERC20;

    IERC20 private immutable _asset;
    uint256 private _currentTimePeriodsElapsed;

    constructor(IERC20 asset_) ERC1155("") {
        _asset = asset_;
    }

    // =============== Utility ===============
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    function currentTimePeriodsElapsed() public view virtual returns (uint256) {
        return _currentTimePeriodsElapsed;
    }

    // =============== Deposit ===============
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 shares);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return convertToSharesForDepositPeriod(assets, currentTimePeriodsElapsed());
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 depositPeriod, uint256 shares) {
        depositPeriod = currentTimePeriodsElapsed();        
        shares = previewDeposit(assets);
        
        _deposit(msg.sender, receiver, depositPeriod, assets, shares);
    }

    function _deposit(address caller, address receiver, uint256 depositPeriod, uint256 assets, uint256 shares) internal virtual {
        _asset.safeTransferFrom(caller, address(this), assets);
        _mint(receiver, depositPeriod, shares, "");
        emit Deposit(msg.sender, receiver, depositPeriod, assets, shares);
    }

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 assets);

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod);
    }

    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        virtual
        returns (uint256 assets)
    {
        // Need to fix
        assets = convertToAssetsForDepositPeriod(shares, depositPeriod);

        //function _withdraw(address caller,address receiver,address owner,uint256 assets,uint256 shares)

        _burn(owner, depositPeriod, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, depositPeriod, assets, shares);
    }
}
