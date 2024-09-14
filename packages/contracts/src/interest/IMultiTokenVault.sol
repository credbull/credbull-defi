// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

/**
 * @dev MultiToken vault able to support multiple independent deposit periods
 * e.g. Deposit 0 and Deposit 1 may have different returns
 */
interface IMultiTokenVault {
    /**
     * @notice See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(uint256 principal, uint256 depositPeriod, uint256 toPeriod)
        external
        view
        returns (uint256 yield);

    // =============== Deposit ===============
    /**
     * @notice Converts a given amount of assets to shares based on a specific time period.
     * @param assets The amount of assets to convert.
     * @param depositPeriod The time period for deposit.
     * @return shares The number of shares corresponding to the assets at the specified time period.
     * @dev MUST be independent of vault's getCurrentTimePeriod()
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /**
     * @notice Converts a given amount of assets to shares at the current time period
     * @param assets The amount of assets to convert.
     * @return shares The number of shares corresponding to the assets at the specified time period.
     * @dev MUST assume depositId = getCurrentTimePeriod()
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Previews the deposit for a given amount of assets at the current time period
     * @param assets The amount of assets to convert.
     * @return shares The number of shares corresponding to the assets at the specified time period.
     * @dev MUST assume depositId = getCurrentTimePeriod()
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    // =============== Redeem ===============

    /**
     * @notice Converts a given amount of shares to assets based on a specific time period.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The time period of deposit
     * @param redeemPeriod The time period of redeem
     * @return assets The number of assets corresponding to the shares at the specified time period.
     * @dev  MUST be independent of vault's getCurrentTimePeriod()
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    // MUST be independent of vault's getCurrentTimePeriod()
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    // MUST be independent of vault's getCurrentTimePeriod()
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    // MUST assume redeemPeriod = getCurrentTimePeriod()
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    // MUST assume redeemPeriod = getCurrentTimePeriod()
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    // MUST assume redeemPeriod = getCurrentTimePeriod()
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    // TODO - add withdraw functions as well
    //    function previewWithdrawForPeriods(uint256 assets, uint256 depositTimePeriod, uint256 redeemTimePeriod) external view returns (uint256 shares);
    //    function withdrawForPeriods(uint256 assets, address receiver, address owner, uint256 depositTimePeriod, uint256 redeemTimePeriod) external returns (uint256 shares);

    // =============== Utility ===============

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
