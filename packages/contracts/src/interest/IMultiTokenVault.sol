// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

/**
 * @dev A vault that using Principal and Discounting for asset and shares respectively
 */
interface IMultiTokenVault {
    // =============== Deposit ===============

    // MUST be independent of vault's getCurrentTimePeriod()
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    // MUST assume depositId = getCurrentTimePeriod()
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    // MUST assume depositId = getCurrentTimePeriod()
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    // =============== Redeem ===============

    // MUST be independent of vault's getCurrentTimePeriod()
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
