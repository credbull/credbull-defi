// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { DiscountVault } from "@credbull/interest/DiscountVault.sol";
import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * @title IdentityDiscountVault
 * @dev DiscountVault where Assets (Principal) = Shares (Discount)
 */
contract IdentityDiscountVault is DiscountVault {
    IERC1155MintAndBurnable public immutable DEPOSITS;

    /**
     * @notice Constructor to initialize the SimpleInterestVault with asset, interest rate, frequency, and tenor.
     * @param asset The ERC20 token that represents the underlying asset.
     * @param interestRatePercentage The annual interest rate as a percentage.
     */
    constructor(IERC20Metadata asset, IERC1155MintAndBurnable depositLedger, uint256 interestRatePercentage)
        DiscountVault(asset, interestRatePercentage, 1, 0)
    {
        DEPOSITS = depositLedger;
    }

    function calcPrice(uint256 /* numTimePeriodsElapsed */ ) public view override returns (uint256 price) {
        return SCALE;
    }

    function deposit(uint256 assets, address receiver) public virtual override(ERC4626, IERC4626) returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);

        // update ledger as last step
        DEPOSITS.mint(receiver, getCurrentTimePeriodsElapsed(), shares, "");

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override(ERC4626, IERC4626)
        returns (uint256)
    {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        // update ledger before redeem
        DEPOSITS.burn(owner, getCurrentTimePeriodsElapsed(), shares);

        uint256 assets = super.redeem(shares, receiver, owner);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override(ERC4626, IERC4626)
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        // update ledger before withdraw
        DEPOSITS.burn(owner, getCurrentTimePeriodsElapsed(), assets);

        uint256 shares = super.withdraw(assets, receiver, owner);

        return shares;
    }
}
