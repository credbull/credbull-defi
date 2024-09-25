// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMultiTokenVault is IERC1155 {
    event Deposit(
        address indexed sender, address indexed receiver, uint256 depositPeriod, uint256 assets, uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    );

    function asset() external view returns (address);
    function currentTimePeriodsElapsed() external view returns (uint256);

    // =============== Deposit ===============

    /**
     * @dev can get shares using depositPeriod (including prior depsoitPeriods)
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /**
     * @dev convert shares at the current deposit Period under ideal circumstances
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev calculate shares at the current deposit Period under real circumstances
     * Need to consider about fees etc
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 depositPeriod, uint256 shares);

    // =============== Redeem ===============
    function maxRedeem(address owner, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 maxShares);

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    // =============== Operational ===============
    /**
     * @dev This function is for only testing purposes
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
