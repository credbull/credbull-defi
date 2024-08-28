// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IProduct {
    // ===============  vault / vault-like behaviour ===============

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 depositTimePeriodElapsed)
        external
        returns (uint256 assets);

    // =============== metadata ===============
    // meta-data related
    function getFrequency() external view returns (uint256 frequency); // e.g. Days, Months, or Years

    function getInterestInPercentage() external view returns (uint256 interestRateInPercentage); // e.g. 6%, 12%

    // represents number of periods (days, months, years) in the contract since "start"
    // Krishna's implementation refers to this as "Window"
    function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

    // ===============  testing purposes only ===============

    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
