// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @dev MultiToken vault supporting multiple independent deposit periods.
 * For example, Deposit 0 and Deposit 1 may have different returns or redemption rules.
 */
interface IMultiTokenVault {
    /**
     * @notice Calculates the yield for a given principal between deposit and redeem periods.
     * @dev See {CalcSimpleInterest-calcInterest}.
     */
    function calcYield(uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 yield);

    // =============== Deposit ===============

    /**
     * @notice Converts a given amount of assets to shares based on a specific deposit period.
     * @param assets The amount of assets to convert.
     * @param depositPeriod The deposit period for which the shares are calculated.
     * @return shares The number of shares corresponding to the assets at the specified deposit period.
     * @dev MUST be independent of vault's getCurrentTimePeriodsElapsed().
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /**
     * @notice Converts a given amount of assets to shares at the current time period.
     * @param assets The amount of assets to convert.
     * @return shares The number of shares corresponding to the assets at the current time period.
     * @dev MUST assume depositPeriod = getCurrentTimePeriodsElapsed().
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Previews the deposit for a given amount of assets at the current time period.
     * @param assets The amount of assets to preview.
     * @return shares The number of shares corresponding to the assets at the current time period.
     * @dev MUST assume depositPeriod = getCurrentTimePeriodsElapsed().
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Deposits the given amount of assets at the current time period.
     * @param assets The amount of assets to deposit.
     * @param receiver The address to receive the shares.
     * @return shares The number of shares corresponding to the assets at the current time period.
     * @dev MUST assume depositPeriod = getCurrentTimePeriodsElapsed().
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    // =============== Redeem ===============

    /**
     * @notice Converts a given amount of shares to assets based on specific deposit and redeem periods.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The deposit period for the shares.
     * @param redeemPeriod The redeem period for which the assets are calculated.
     * @return assets The number of assets corresponding to the shares at the specified periods.
     * @dev MUST be independent of vault's getCurrentTimePeriodsElapsed().
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Previews the redeem for a given amount of shares based on specific deposit and redeem periods.
     * @param shares The amount of shares to preview.
     * @param depositPeriod The deposit period for the shares.
     * @param redeemPeriod The redeem period for the assets.
     * @return assets The number of assets corresponding to the shares at the specified periods.
     * @dev MUST be independent of vault's getCurrentTimePeriodsElapsed().
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Redeems a given amount of shares for assets based on specific deposit and redeem periods.
     * @param shares The amount of shares to redeem.
     * @param receiver The address receiving the redeemed assets.
     * @param owner The address of the owner of the shares.
     * @param depositPeriod The deposit period for the shares.
     * @param redeemPeriod The redeem period for the assets.
     * @return assets The number of assets redeemed for the shares at the specified periods.
     * @dev MUST be independent of vault's getCurrentTimePeriodsElapsed().
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    /**
     * @notice Converts a given amount of shares to assets based on a specific deposit period and the current redeem period.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The deposit period for the shares.
     * @return assets The number of assets corresponding to the shares at the current redeem period.
     * @dev MUST assume redeemPeriod = getCurrentTimePeriodsElapsed().
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Previews the redeem for a given amount of shares based on a specific deposit period and the current redeem period.
     * @param shares The amount of shares to preview.
     * @param depositPeriod The deposit period for the shares.
     * @return assets The number of assets corresponding to the shares at the current redeem period.
     * @dev MUST assume redeemPeriod = getCurrentTimePeriodsElapsed().
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Redeems a given amount of shares for assets based on a specific deposit period and the current redeem period.
     * @param shares The amount of shares to redeem.
     * @param receiver The address receiving the redeemed assets.
     * @param owner The address of the owner of the shares.
     * @param depositPeriod The deposit period for the shares.
     * @return assets The number of assets redeemed for the shares at the current redeem period.
     * @dev MUST assume redeemPeriod = getCurrentTimePeriodsElapsed().
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    // =============== Utility ===============
    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     */
    function getAsset() external view returns (IERC20 asset);

    /**
     * @notice Retrieves the number of shares an account holds for a specific deposit period.
     * @param account The address of the account.
     * @param depositPeriod The deposit period for which to retrieve the shares.
     * @return shares The number of shares held by the account for the specified deposit period.
     */
    function getSharesAtPeriod(address account, uint256 depositPeriod) external view returns (uint256 shares);

    /**
     * @notice Gets the current number of time periods elapsed.
     * @return currentTimePeriodsElapsed The number of time periods elapsed.
     */
    function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

    // =============== Testing Purposes Only ===============

    /**
     * @notice Sets the current number of time periods elapsed.
     * @dev This function is intended for testing purposes to simulate the passage of time.
     * @param currentTimePeriodsElapsed The number of time periods to set as elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
