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

    error MultiTokenVault__ExceededMaxRedeem();
    error MultiTokenVault__RedeemBeforeDeposit();
    error MultiTokenVault__CallerMissingApprovalForAll();

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

    function _deposit(address caller, address receiver, uint256 depositPeriod, uint256 assets, uint256 shares)
        internal
        virtual
    {
        _asset.safeTransferFrom(caller, address(this), assets);
        _mint(receiver, depositPeriod, shares, "");
        emit Deposit(msg.sender, receiver, depositPeriod, assets, shares);
    }

    // =============== Redeem ===============
    function maxRedeem(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return balanceOf(owner, depositPeriod);
    }

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets);

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed());
    }

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed());
    }

    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public virtual returns (uint256 assets) {
        if (depositPeriod >= redeemPeriod) {
            revert MultiTokenVault__RedeemBeforeDeposit();
        }

        uint256 maxShares = maxRedeem(owner, depositPeriod);

        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem();
        }

        assets = previewRedeemForDepositPeriod(shares, depositPeriod, redeemPeriod);

        _withdraw(msg.sender, receiver, owner, depositPeriod, assets, shares);
    }

    function redeemForDepositPeriod(
        uint256 shares, address receiver, address owner, uint256 depositPeriod
    ) public virtual returns (uint256 assets) {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed());
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if(caller != owner && isApprovedForAll(owner, caller)) {
            revert MultiTokenVault__CallerMissingApprovalForAll();
        }

        _burn(owner, depositPeriod, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, depositPeriod, assets, shares);
    }
}
