// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MultiTokenVault } from "./MultiTokenVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";
import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

/**
 * @title SimpleMultiTokenVault
 * @dev A concrete implementation of the MultiTokenVault contract.
 *      This vault uses a simple yield calculation strategy with a fixed asset-to-shares ratio and yield percentage.
 *      It includes access control for managing deposit periods.
 */
contract SimpleMultiTokenVault is MultiTokenVault {
    using SafeERC20 for IERC20;

    /// @notice The yield strategy contract used to calculate yield.
    IYieldStrategy public immutable YIELD_STRATEGY;

    /// @notice The contract context for calculating interest.
    ICalcInterestMetadata CONTEXT;

    /**
     * @notice Constructor to initialize the vault with the asset, URI, asset-to-shares ratio, and yield strategy.
     * @param _treasury The address of the treasury where assets will be transferred.
     * @param _asset The ERC20 token that represents the underlying asset.
     * @param _uri The URI for ERC1155 token metadata.
     * @param yieldStrategy The yield strategy contract to calculate yield.
     * @param context The contract implementation to calculate interest.
     * @param assetToSharesRatio The ratio of assets to shares (e.g., 1:1).
     * @param initialOwner The initial owner of the contract (passed to Ownable).
     */
    constructor(
        address _treasury,
        IERC20 _asset,
        string memory _uri,
        IYieldStrategy yieldStrategy,
        ICalcInterestMetadata context,
        uint256 assetToSharesRatio,
        address initialOwner
    ) MultiTokenVault(_treasury, _asset, _uri, initialOwner) {
        require(assetToSharesRatio > 0, "Asset to shares ratio must be greater than 0");

        YIELD_STRATEGY = yieldStrategy;
        CONTEXT = context;

        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
    }

    // =============== Yield Calculation ===============

    /**
     * @notice Calculate the yield based on the principal amount.
     * @param principal The principal amount deposited.
     * @param depositPeriod The specific period when the deposit was made.
     * @param redeemPeriod The period in which redemption occurs.
     * @return yieldAmount The calculated yield based on the principal and yield percentage.
     */
    function calcYield(uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 yieldAmount)
    {
        if (depositPeriod > redeemPeriod) {
            revert MultiTokenVault__RedeemTimePeriodNotSupported(owner(), depositPeriod, redeemPeriod);
        }

        if (currentTimePeriodsElapsed != redeemPeriod) {
            revert MultiTokenVault__RedeemTimePeriodNotSupported(owner(), currentTimePeriodsElapsed, redeemPeriod);
        }

        return YIELD_STRATEGY.calcYield(address(CONTEXT), principal, depositPeriod, redeemPeriod);
    }

    // =============== Conversion Functions ===============

    /**
     * @notice Converts a given amount of assets to shares for a specific deposit period.
     * @dev Uses the asset-to-shares ratio to calculate the shares from assets.
     * @param assets The amount of assets to convert.
     * @param depositPeriod The specific deposit period during which the assets are converted to shares.
     * @return shares The number of shares corresponding to the assets.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 shares)
    {
        return assets / ASSET_TO_SHARES_RATIO;
    }

    /**
     * @notice Converts a given number of shares to assets for a specific deposit and redemption period.
     * @dev The conversion includes the principal and the calculated yield.
     * @param shares The number of shares to convert.
     * @param depositPeriod The specific deposit period during which the shares were issued.
     * @param redeemPeriod The period in which the assets are redeemed.
     * @return assets The amount of assets corresponding to the shares.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 principal = shares * ASSET_TO_SHARES_RATIO;
        uint256 yieldAmount = calcYield(principal, depositPeriod, redeemPeriod);
        return principal + yieldAmount;
    }

    /**
     * @notice Converts a given number of shares to assets for a specific deposit period using the current time period.
     * @param shares The number of shares to convert.
     * @param depositPeriod The specific deposit period during which the shares were issued.
     * @return assets The amount of assets corresponding to the shares.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed);
    }

    // =============== Redeem Functions ===============

    /**
     * @notice Redeem shares and burn the deposit-period-specific ERC1155 tokens.
     * @dev Burns the ERC1155 tokens for the specific deposit period and transfers the corresponding assets to the receiver.
     * @param shares The number of shares to redeem.
     * @param receiver The address receiving the redeemed assets.
     * @param owner The address of the owner of the shares.
     * @param depositPeriod The specific deposit period for which the shares were issued.
     * @return assets The amount of assets redeemed.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        virtual
        override
        returns (uint256 assets)
    {
        return super.redeemForDepositPeriod(shares, receiver, owner, depositPeriod);
    }

    /**
     * @notice Preview the number of assets that will be redeemed for a given number of shares.
     * @param shares The number of shares to redeem.
     * @param depositPeriod The specific deposit period during which the shares were issued.
     * @param redeemPeriod The period in which redemption occurs.
     * @return assets The amount of assets that will be redeemed.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    /**
     * @notice Get the total balance of assets currently deposited in the vault.
     * @return The total deposited assets converted to shares.
     */
    function getTotalBalance() public view override returns (uint256) {
        return convertToShares(totalDepositedAssets);
    }
}
