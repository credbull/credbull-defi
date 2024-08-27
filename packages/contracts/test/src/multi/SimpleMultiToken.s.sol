// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import { IERC4626Interest } from "./IERC4626Interest.s.sol";

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleMultiToken is ERC1155, ERC1155Supply, IERC4626Interest, Ownable {
    uint256 public constant PERIODS_0 = 0;
    uint256 public constant PERIODS_1 = 1;
    uint256 public constant PERIODS_2 = 2;
    uint256 public constant PERIODS_3 = 3;
    uint256 public constant PERIODS_4 = 4;
    uint256 public constant PERIODS_5 = 5;
    uint256 public constant PERIODS_6 = 6;
    uint256 public constant PERIODS_7 = 7;
    uint256 public constant PERIODS_8 = 8;
    uint256 public constant PERIODS_9 = 9;
    uint256 public constant PERIODS_10 = 10;
    uint256 public constant PERIODS_11 = 11;
    uint256 public constant PERIODS_12 = 12;
    uint256 public constant PERIODS_13 = 13;
    uint256 public constant PERIODS_14 = 14;
    uint256 public constant PERIODS_15 = 15;
    uint256 public constant PERIODS_16 = 16;
    uint256 public constant PERIODS_17 = 17;
    uint256 public constant PERIODS_18 = 18;
    uint256 public constant PERIODS_19 = 19;
    uint256 public constant PERIODS_20 = 20;
    uint256 public constant PERIODS_21 = 21;
    uint256 public constant PERIODS_22 = 22;
    uint256 public constant PERIODS_23 = 23;
    uint256 public constant PERIODS_24 = 24;
    uint256 public constant PERIODS_25 = 25;
    uint256 public constant PERIODS_26 = 26;
    uint256 public constant PERIODS_27 = 27;
    uint256 public constant PERIODS_28 = 28;
    uint256 public constant PERIODS_29 = 29;
    uint256 public constant PERIODS_30 = 30;
    uint256 public constant PERIODS_31 = 31;
    uint256 public constant PERIODS_32 = 32;
    uint256 public constant PERIODS_33 = 33;
    uint256 public constant PERIODS_34 = 34;
    uint256 public constant PERIODS_35 = 35;
    uint256 public constant PERIODS_36 = 36;
    uint256 public constant PERIODS_37 = 37;
    uint256 public constant PERIODS_38 = 38;
    uint256 public constant PERIODS_39 = 39;
    uint256 public constant PERIODS_40 = 40;
    uint256 public constant PERIODS_41 = 41;
    uint256 public constant PERIODS_42 = 42;
    uint256 public constant PERIODS_43 = 43;
    uint256 public constant PERIODS_44 = 44;
    uint256 public constant PERIODS_45 = 45;
    uint256 public constant PERIODS_46 = 46;
    uint256 public constant PERIODS_47 = 47;
    uint256 public constant PERIODS_48 = 48;
    uint256 public constant PERIODS_49 = 49;
    uint256 public constant PERIODS_50 = 50;
    uint256 public constant PERIODS_51 = 51;
    uint256 public constant PERIODS_52 = 52;
    uint256 public constant PERIODS_53 = 53;
    uint256 public constant PERIODS_54 = 54;
    uint256 public constant PERIODS_55 = 55;
    uint256 public constant PERIODS_56 = 56;
    uint256 public constant PERIODS_57 = 57;
    uint256 public constant PERIODS_58 = 58;
    uint256 public constant PERIODS_59 = 59;
    uint256 public constant PERIODS_60 = 60;

    IERC20 public immutable ASSET;
    uint256 public immutable TENOR;
    uint256 private currentTimePeriodsElapsed = 0; // the current number of time periods elapse

    error AssetTransferFailed();
    error InsufficientAssetsInVault();

    error WithdrawNotSupported();
    error TransferNotSupported();
    error AllowanceNotSupported();
    error ApproveNotSupported();

    constructor(address _initialOwner, IERC20 _asset, uint256 _tenor)
        ERC1155("credbull.io/funds/1")
        Ownable(_initialOwner)
    {
        ASSET = _asset;
        TENOR = _tenor;
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }

    // ============== IERC4626Interest ==============

    function convertToSharesAtPeriod(uint256 assets, uint256 /*numTimePeriodsElapsed */ )
        public
        pure
        override
        returns (uint256 shares)
    {
        return assets;
    }

    function convertToAssetsAtPeriod(uint256 shares, uint256 numTimePeriodsElapsed)
        public
        view
        override
        returns (uint256 assets)
    {
        if (TENOR > numTimePeriodsElapsed) return 0; // no early redeems allowed

        return shares;
    }

    function getCurrentTimePeriodsElapsed() public view returns (uint256) {
        return currentTimePeriodsElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    function getTenor() external view override returns (uint256) {
        return TENOR;
    }

    function calcInterest(uint256, /* principal */ uint256 /* numTimePeriodsElapsed */ )
        public
        pure
        returns (uint256 interest)
    {
        return 0;
    }

    function calcDiscounted(uint256 principal, uint256 /* numTimePeriodsElapsed */ )
        public
        pure
        returns (uint256 discounted)
    {
        return principal;
    }

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 /* numTimePeriodsElapsed */ )
        public
        pure
        returns (uint256 principal)
    {
        return discounted;
    }

    function getFrequency() public pure returns (uint256 frequency) {
        return 360;
    }

    function getInterestInPercentage() public pure returns (uint256 interestRateInPercentage) {
        return 12;
    }

    // ============== IERC4626 ==============

    function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
        uint256 _shares = convertToShares(assets);

        // Transfer the USDC (assets) from the receiver to the vault
        bool success = ASSET.transferFrom(receiver, address(this), assets);

        if (!success) {
            revert AssetTransferFailed();
        }

        // Mint the vault shares to the receiver
        _mint(receiver, currentTimePeriodsElapsed, _shares, "");

        return _shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public returns (uint256 assets) {
        if (TENOR > currentTimePeriodsElapsed) return 0;
        uint256 _assets = convertToAssets(shares);

        // Ensure the vault has enough assets to pay out
        if (_assets > ASSET.balanceOf(address(this))) {
            revert InsufficientAssetsInVault();
        }

        uint256 depositPeriod = currentTimePeriodsElapsed - TENOR;

        // Burn the shares
        _burn(owner, depositPeriod, shares);

        // Transfer the assets (e.g., USDC) from the vault to the receiver
        bool success = ASSET.transfer(receiver, _assets);
        if (!success) {
            revert AssetTransferFailed();
        }

        return _assets;
    }

    function asset() public view returns (address assetTokenAddress) {
        return address(ASSET);
    }

    function totalAssets() public view returns (uint256 totalManagedAssets) {
        return totalSupply();
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        return convertToSharesAtPeriod(assets, currentTimePeriodsElapsed);
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        return convertToAssetsAtPeriod(shares, currentTimePeriodsElapsed);
    }

    function maxDeposit(address /* receiver */ ) public pure returns (uint256 maxAssets) {
        return type(uint256).max; // TODO - need to implement correctly, should look at current receiver balance
    }

    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        return convertToShares(assets);
    }

    function maxMint(address /* receiver */ ) public pure returns (uint256 maxShares) {
        return type(uint256).max; // TODO - need to implement correctly, should look at current receiver balance
    }

    function previewMint(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function mint(uint256 shares, address receiver) public returns (uint256 assets) {
        uint256 _assets = convertToAssets(shares);

        _mint(receiver, currentTimePeriodsElapsed, shares, "");

        return _assets;
    }

    function maxWithdraw(address /* owner */ ) public pure returns (uint256 maxAssets) {
        return 0; // TODO - MUST NOT revert.  // However our use is redeem shares for assets.
    }

    function previewWithdraw(uint256 /* assets */ ) public pure returns (uint256 shares) {
        return 0; // TODO - MUST NOT revert.  // However our use is redeem shares for assets.
    }

    function withdraw(uint256, /* assets */ address, /* receiver */ address /* owner */ )
        public
        pure
        returns (uint256 /* shares */ )
    {
        revert WithdrawNotSupported();
    }

    function maxRedeem(address owner) external view returns (uint256 maxShares) {
        return convertToAssets(balanceOf(owner, currentTimePeriodsElapsed));
    }

    function previewRedeem(uint256 shares) external view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    // ============== IERC20 ==============

    function totalSupply() public view override(ERC1155Supply, IERC20) returns (uint256) {
        return ERC1155Supply.totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOf(account, currentTimePeriodsElapsed);
    }

    function transfer(address, /* to */ uint256 /* value */ ) public pure returns (bool) {
        revert TransferNotSupported();
    }

    function allowance(address, /* owner */ address /* spender */ ) public pure returns (uint256) {
        revert AllowanceNotSupported();
    }

    function approve(address, /* spender */ uint256 /* value */ ) public pure returns (bool) {
        revert AllowanceNotSupported();
    }

    function transferFrom(address, /* from */ address, /* to */ uint256 /* value */ ) public pure returns (bool) {
        revert TransferNotSupported();
    }

    // ============== IERC20 MetaData ==============

    function name() public pure returns (string memory) {
        return "Simple Multi Token";
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public pure returns (string memory) {
        return "SMT";
    }

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() public pure returns (uint8) {
        return 18;
    }
}
