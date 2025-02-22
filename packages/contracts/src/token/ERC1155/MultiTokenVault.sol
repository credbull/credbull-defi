// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { ERC1155SupplyUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { ERC1155PausableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title MultiTokenVault
 * @dev A vault that uses deposit-period-specific ERC1155 tokens to represent deposits.
 *      This contract manages deposits and redemptions using ERC1155 tokens. It tracks the number
 *      of time periods that have elapsed and allows users to deposit and redeem assets based on these periods.
 *      Designed to be secure and production-ready for Hacken audit.
 */
abstract contract MultiTokenVault is
    Initializable,
    ERC1155SupplyUpgradeable,
    ERC1155PausableUpgradeable,
    IMultiTokenVault,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token used as the underlying asset in the vault.
    IERC20 private ASSET;

    error MultiTokenVault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 maxShares);
    error MultiTokenVault__ExceededMaxDeposit(
        address receiver, uint256 depositPeriod, uint256 assets, uint256 maxAssets
    );
    error MultiTokenVault__RedeemTimePeriodNotSupported(address owner, uint256 period, uint256 redeemPeriod);
    error MultiTokenVault__CallerMissingApprovalForAll(address operator, address owner);
    error MultiTokenVault__RedeemBeforeDeposit(address owner, uint256 depositPeriod, uint256 redeemPeriod);
    error MultiTokenVault__InvalidArrayLength(uint256 depositPeriodsLength, uint256 sharesLength);

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the vault with the asset, treasury, and token URI for ERC1155 tokens.
     * @param asset_ The ERC20 token representing the underlying asset.
     */
    function __MultiTokenVault_init(IERC20 asset_) internal onlyInitializing {
        __ERC1155Supply_init();
        __ERC1155Pausable_init();
        __ReentrancyGuard_init();
        ASSET = asset_;
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        return _depositForDepositPeriod(assets, receiver, currentPeriodsElapsed());
    }

    function _depositForDepositPeriod(uint256 assets, address receiver, uint256 depositPeriod)
        internal
        virtual
        returns (uint256 shares)
    {
        uint256 maxAssets = maxDeposit(receiver);

        if (assets > maxAssets) {
            revert MultiTokenVault__ExceededMaxDeposit(receiver, depositPeriod, assets, maxAssets);
        }

        shares = previewDeposit(assets);

        _deposit(_msgSender(), receiver, depositPeriod, assets, shares);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        virtual
        returns (uint256)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public virtual returns (uint256 assets) {
        if (depositPeriod > redeemPeriod) {
            revert MultiTokenVault__RedeemBeforeDeposit(owner, depositPeriod, redeemPeriod);
        }

        if (currentPeriodsElapsed() < redeemPeriod) {
            revert MultiTokenVault__RedeemTimePeriodNotSupported(owner, currentPeriodsElapsed(), redeemPeriod);
        }

        uint256 maxShares = maxRedeemAtPeriod(owner, depositPeriod);

        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        assets = previewRedeemForDepositPeriod(shares, depositPeriod, redeemPeriod);

        _withdraw(_msgSender(), receiver, owner, depositPeriod, assets, shares);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function asset() public view virtual returns (address asset_) {
        return address(ASSET);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function sharesAtPeriod(address owner, uint256 depositPeriod) public view returns (uint256 shares) {
        return balanceOf(owner, depositPeriod);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 shares);

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function maxRedeemAtPeriod(address owner, uint256 depositPeriod) public view virtual returns (uint256 maxShares) {
        return balanceOf(owner, depositPeriod);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets);

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToAssetsForDepositPeriodBatch(
        uint256[] memory shares,
        uint256[] memory depositPeriods,
        uint256 redeemPeriod
    ) external view returns (uint256[] memory assets_) {
        if (shares.length != depositPeriods.length) {
            revert MultiTokenVault__InvalidArrayLength(depositPeriods.length, shares.length);
        }

        uint256[] memory assets = new uint256[](depositPeriods.length);
        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            assets[i] = convertToAssetsForDepositPeriod(shares[i], depositPeriods[i], redeemPeriod);
        }

        return assets;
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function currentPeriodsElapsed() public view virtual returns (uint256 currentPeriod_);

    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     *      This function checks for support of the IERC1155 interface, IMultiTokenVault interface,
     *      and delegates to the super class for any other interface support checks.
     *
     * @param interfaceId The identifier of the interface to check for support.
     *
     * @return bool True if the contract supports the requested interface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IMultiTokenVault).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev An internal function to implement the functionality of depositing assets into the vault
     *      and mints shares for the current time period.
     *
     * @param caller The address of who is depositing the assets.
     * @param receiver The address that will receive the minted shares.
     * @param depositPeriod The time period in which the assets are deposited.
     * @param assets The amount of the ERC-20 underlying assets to be deposited into the vault.
     * @param shares The amount of ERC-1155 tokens minted.
     */
    function _deposit(address caller, address receiver, uint256 depositPeriod, uint256 assets, uint256 shares)
        internal
        virtual
        nonReentrant
    {
        ASSET.safeTransferFrom(caller, address(this), assets);
        _mint(receiver, depositPeriod, shares, "");
        emit Deposit(caller, receiver, depositPeriod, assets, shares);
    }

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner,
     *      while the redemption happens at the defined redeem period
     *      And return the equivalent amount of assets to the receiver.
     *
     * @param caller The address of who is redeeming the shares.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The deposit period in which the shares were minted.
     * @param assets The equivalent amount of the ERC-20 underlying assets.
     * @param shares The amount of the ERC-1155 tokens to redeem.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    ) internal virtual nonReentrant {
        if (caller != owner && !isApprovedForAll(owner, caller)) {
            revert MultiTokenVault__CallerMissingApprovalForAll(caller, owner);
        }

        _burn(owner, depositPeriod, shares);

        ASSET.safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, depositPeriod, assets, shares);
    }

    /**
     * @dev Withdraws the assets from the vault.
     *
     * @param to The address that will receive the assets.
     * @param amount The amount of the ERC-20 underlying assets to be withdrawn from the vault.
     */
    function _withdrawAssest(address to, uint256 amount) internal virtual {
        ASSET.safeTransfer(to, amount);

        emit AssetTransfer(_msgSender(), to, asset(), amount);
    }

    /**
     * @inheritdoc ERC1155SupplyUpgradeable
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override(ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable)
        whenNotPaused
    {
        ERC1155SupplyUpgradeable._update(from, to, ids, values);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC1155)
        returns (uint256)
    {
        return ERC1155Upgradeable.balanceOf(account, id);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC1155)
        returns (uint256[] memory)
    {
        return ERC1155Upgradeable.balanceOfBatch(accounts, ids);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override(ERC1155Upgradeable, IERC1155)
        returns (bool)
    {
        return ERC1155Upgradeable.isApprovedForAll(account, operator);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC1155Upgradeable, IERC1155) {
        ERC1155Upgradeable.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        virtual
        override(ERC1155Upgradeable, IERC1155)
    {
        ERC1155Upgradeable.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IERC1155) {
        ERC1155Upgradeable.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
