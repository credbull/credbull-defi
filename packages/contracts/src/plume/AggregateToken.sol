// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import { ComponentToken } from "./ComponentToken.sol";
import { IAggregateToken } from "./interfaces/IAggregateToken.sol";
import { IComponentToken } from "./interfaces/IComponentToken.sol";

/**
 * @title AggregateToken
 * @author Eugene Y. Q. Shen
 * @notice Implementation of the abstract ComponentToken that represents a basket of ComponentTokens
 */
contract AggregateToken is ComponentToken, IAggregateToken, IERC1155Receiver {
    // Storage

    /// @custom:storage-location erc7201:plume.storage.AggregateToken
    struct AggregateTokenStorage {
        /// @dev List of all ComponentTokens that have ever been added to the AggregateToken
        IComponentToken[] componentTokenList;
        /// @dev Mapping of all ComponentTokens that have ever been added to the AggregateToken
        mapping(IComponentToken componentToken => bool exists) componentTokenMap;
        /// @dev Price at which users can buy the AggregateToken using `asset`, times the base
        uint256 askPrice;
        /// @dev Price at which users can sell the AggregateToken to receive `asset`, times the base
        uint256 bidPrice;
    }

    // keccak256(abi.encode(uint256(keccak256("plume.storage.AggregateToken")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AGGREGATE_TOKEN_STORAGE_LOCATION =
        0xd3be8f8d43881152ac95daeff8f4c57e01616286ffd74814a5517f422a6b6200;

    function _getAggregateTokenStorage() private pure returns (AggregateTokenStorage storage $) {
        assembly {
            $.slot := AGGREGATE_TOKEN_STORAGE_LOCATION
        }
    }

    // Constants

    // Base that is used to divide all price inputs in order to represent e.g. 1.000001 as 1000001e12
    uint256 private constant _BASE = 1e18;

    // Errors

    /**
     * @notice Indicates a failure because the ComponentToken is already in the component token list
     * @param componentToken ComponentToken that is already in the component token list
     */
    error ComponentTokenAlreadyListed(IComponentToken componentToken);

    /**
     * @notice Indicates a failure because the ComponentToken is not in the component token list
     * @param componentToken ComponentToken that is not in the component token list
     */
    error ComponentTokenNotListed(IComponentToken componentToken);

    /**
     * @notice Indicates a failure because the ComponentToken has a non-zero balance
     * @param componentToken ComponentToken that has a non-zero balance
     */
    error ComponentTokenBalanceNonZero(IComponentToken componentToken);

    /**
     * @notice Indicates a failure because the ComponentToken is the current `asset
     * @param componentToken ComponentToken that is the current `asset`
     */
    error ComponentTokenIsAsset(IComponentToken componentToken);

    /**
     * @notice Indicates a failure because the given `asset` does not match the actual `asset`
     * @param invalidAsset Asset that does not match the actual `asset`
     * @param asset Actual `asset` for the AggregateToken
     */
    error InvalidAsset(IERC20 invalidAsset, IERC20 asset);

    // Initializer

    /**
     * @notice Prevent the implementation contract from being initialized or reinitialized
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the AggregateToken
     * @param owner Address of the owner of the AggregateToken
     * @param name Name of the AggregateToken
     * @param symbol Symbol of the AggregateToken
     * @param asset_ Asset used to mint and burn the AggregateToken
     * @param askPrice Price at which users can buy the AggregateToken using `asset`, times the base
     * @param bidPrice Price at which users can sell the AggregateToken to receive `asset`, times the base
     */
    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        IComponentToken asset_,
        uint256 askPrice,
        uint256 bidPrice
    ) public initializer {
        super.initialize(owner, name, symbol, IERC20(address(asset_)), false, false);

        AggregateTokenStorage storage $ = _getAggregateTokenStorage();
        $.componentTokenList.push(asset_);
        $.componentTokenMap[asset_] = true;
        $.askPrice = askPrice;
        $.bidPrice = bidPrice;
    }

    // Override Functions

    /**
     * @inheritdoc IERC4626
     * @dev 1:1 conversion rate between USDT and base asset
     */
    function convertToShares(uint256 assets)
        public
        view
        override(ComponentToken, IComponentToken)
        returns (uint256 shares)
    {
        return assets * _BASE / _getAggregateTokenStorage().askPrice;
    }

    /**
     * @inheritdoc IERC4626
     * @dev 1:1 conversion rate between USDT and base asset
     */
    function convertToAssets(uint256 shares)
        public
        view
        override(ComponentToken, IComponentToken)
        returns (uint256 assets)
    {
        return shares * _getAggregateTokenStorage().bidPrice / _BASE;
    }

    /// @inheritdoc IComponentToken
    function asset() public view override(ComponentToken, IComponentToken) returns (address assetTokenAddress) {
        return super.asset();
    }

    /// @inheritdoc IComponentToken
    function redeem(uint256 shares, address receiver, address controller)
        public
        override(ComponentToken, IComponentToken)
        returns (uint256 assets)
    {
        return super.redeem(shares, receiver, controller);
    }

    /// @inheritdoc IComponentToken
    function totalAssets() public view override(ComponentToken, IComponentToken) returns (uint256 totalManagedAssets) {
        return super.totalAssets();
    }

    // Admin Functions

    /**
     * @notice Add a ComponentToken to the component token list
     * @dev Only the owner can call this function, and there is no way to remove a ComponentToken later
     * @param componentToken ComponentToken to add
     */
    function addComponentToken(IComponentToken componentToken) external onlyRole(ADMIN_ROLE) {
        AggregateTokenStorage storage $ = _getAggregateTokenStorage();
        if ($.componentTokenMap[componentToken]) {
            revert ComponentTokenAlreadyListed(componentToken);
        }
        $.componentTokenList.push(componentToken);
        $.componentTokenMap[componentToken] = true;
        emit ComponentTokenListed(componentToken);
    }

    /**
     * @notice Buy ComponentToken using `asset`
     * @dev Only the owner can call this function, will revert if
     *   the AggregateToken does not have enough `asset` to buy the ComponentToken
     * @param componentToken ComponentToken to buy
     * @param assets Amount of `asset` to pay to receive the ComponentToken
     */
    function buyComponentToken(IComponentToken componentToken, uint256 assets) public onlyRole(ADMIN_ROLE) {
        AggregateTokenStorage storage $ = _getAggregateTokenStorage();

        if (!$.componentTokenMap[componentToken]) {
            $.componentTokenList.push(componentToken);
            $.componentTokenMap[componentToken] = true;
            emit ComponentTokenListed(componentToken);
        }

        // ======== added by chai ==========
        IERC20(asset()).approve(address(componentToken), assets);
        // ================

        uint256 componentTokenAmount = componentToken.deposit(assets, address(this), address(this));
        emit ComponentTokenBought(msg.sender, componentToken, componentTokenAmount, assets);
    }

    /**
     * @notice Sell ComponentToken to receive `asset`
     * @dev Only the owner can call this function, will revert if
     *   the ComponentToken does not have enough `asset` to sell to the AggregateToken
     * @param componentToken ComponentToken to sell
     * @param componentTokenAmount Amount of ComponentToken to sell
     */
    function sellComponentToken(IComponentToken componentToken, uint256 componentTokenAmount)
        public
        onlyRole(ADMIN_ROLE)
    {
        uint256 assets = componentToken.redeem(componentTokenAmount, address(this), address(this));
        emit ComponentTokenSold(msg.sender, componentToken, componentTokenAmount, assets);
    }

    // Admin Setter Functions

    /**
     * @notice Set the price at which users can buy the AggregateToken using `asset`
     * @dev Only the owner can call this setter
     * @param askPrice New ask price
     */
    function setAskPrice(uint256 askPrice) external onlyRole(ADMIN_ROLE) {
        _getAggregateTokenStorage().askPrice = askPrice;
    }

    /**
     * @notice Set the price at which users can sell the AggregateToken to receive `asset`
     * @dev Only the owner can call this setter
     * @param bidPrice New bid price
     */
    function setBidPrice(uint256 bidPrice) external onlyRole(ADMIN_ROLE) {
        _getAggregateTokenStorage().bidPrice = bidPrice;
    }

    // Getter View Functions

    /// @notice Price at which users can buy the AggregateToken using `asset`, times the base
    function getAskPrice() external view returns (uint256) {
        return _getAggregateTokenStorage().askPrice;
    }

    /// @notice Price at which users can sell the AggregateToken to receive `asset`, times the base
    function getBidPrice() external view returns (uint256) {
        return _getAggregateTokenStorage().bidPrice;
    }

    /// @notice Get all ComponentTokens that have ever been added to the AggregateToken
    function getComponentTokenList() public view returns (IComponentToken[] memory) {
        return _getAggregateTokenStorage().componentTokenList;
    }

    /**
     * @notice Check if the given ComponentToken is in the component token list
     * @param componentToken ComponentToken to check
     * @return isListed Boolean indicating if the ComponentToken is in the component token list
     */
    function getComponentToken(IComponentToken componentToken) public view returns (bool isListed) {
        return _getAggregateTokenStorage().componentTokenMap[componentToken];
    }

    // === added by chai ===
    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function requestSellComponentToken(IComponentToken componentToken, uint256 componentTokenAmount)
        public
        onlyRole(ADMIN_ROLE)
    {
        //uint256 assets = componentToken.redeem(componentTokenAmount, address(this), address(this));
        // emit ComponentTokenSold(msg.sender, componentToken, componentTokenAmount, assets);

        componentToken.requestRedeem(componentTokenAmount, address(this), address(this));
    }
    //=========================
}
