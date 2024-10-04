// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IComponentToken
 * @dev Interface for buying and selling tokens.
 *
 * Similar to ERC-4626 Tokenized Vault standard, here:
 * - currencyToken is the "asset" ERC20 token.  e.g. USDC or another stablecoin
 * - componentToken is the "share" ERC20 token.  i.e. the Vault token
 * //
 */
interface IComponentToken {
    // --------------------- Plume invoked ---------------------

    /**
     * @notice Submit a request to send currencyTokenAmount of CurrencyToken to buy ComponentToken
     * @param currencyTokenAmount Amount of CurrencyToken to send
     * @return requestId Unique identifier for the buy request
     */
    function requestBuy(uint256 currencyTokenAmount) external returns (uint256 requestId);

    /**
     * @notice Submit a request to send componentTokenAmount of ComponentToken to sell for CurrencyToken
     * @param componentTokenAmount Amount of ComponentToken to send
     * @return requestId Unique identifier for the sell request
     */
    function requestSell(uint256 componentTokenAmount) external returns (uint256 requestId);

    // --------------------- Credbull invoked ---------------------

    /**
     * @notice Executes a request to buy ComponentToken with CurrencyToken
     * @param requestor Address of the user or smart contract that requested the buy
     * @param requestId Unique identifier for the request
     * @param currencyTokenAmount Amount of CurrencyToken to send
     * @param componentTokenAmount Amount of ComponentToken to receive
     */
    function executeBuy(address requestor, uint256 requestId, uint256 currencyTokenAmount, uint256 componentTokenAmount)
        external;

    /**
     * @notice Executes a request to sell ComponentToken for CurrencyToken
     * @param requestor Address of the user or smart contract that requested the sell
     * @param requestId Unique identifier for the request
     * @param currencyTokenAmount Amount of CurrencyToken to receive
     * @param componentTokenAmount Amount of ComponentToken to send
     */
    function executeSell(
        address requestor,
        uint256 requestId,
        uint256 currencyTokenAmount,
        uint256 componentTokenAmount
    ) external;

    /// @notice Returns the version of the ComponentToken interface
    function getVersion() external view returns (uint256 version);
}
