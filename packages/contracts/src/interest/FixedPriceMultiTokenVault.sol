// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { DiscountVault } from "@credbull/interest/DiscountVault.sol";
import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title IdentityDiscountVault
 * @dev DiscountVault where Assets (Principal) = Shares (Discount)
 */
contract FixedPriceMultiTokenVault is DiscountVault {
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

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);

        // update ledger as last step
        DEPOSITS.mint(receiver, getCurrentTimePeriodsElapsed(), shares, "");

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256) {
        uint256 assets = super.redeem(shares, receiver, owner);

        // update ledger after redeem - make sure all checks pass
        DEPOSITS.burn(owner, getCurrentTimePeriodsElapsed(), shares);

        return assets;
    }
}
