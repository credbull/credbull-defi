// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { console2 as console } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IProduct } from "@credbull-spike/contracts/IProduct.sol";
import { TimelockInterestVault } from "@credbull-spike/contracts/ian/fixed/TimelockInterestVault.sol";

import { ProductScenarioTest } from "@credbull-spike-test/scenario/ProductScenarioTest.t.sol";

/**
 * @title Short Term Fixed Yield Vault Scenario Tests using the [TimelockInterestVault]
 * @author credbull
 * @notice This is the product proving tests whereby the specification has been converted to tests.
 */
contract TimelockInterestVaultProductScenarioTest is ProductScenarioTest {
    using Math for uint256;

    /**
     * @dev Creates a [TimelockInterestVault] using the `params` configuration.
     *
     * @param params The [ProductParams] of configuration for the [TimelockInterestVault].
     * @return The [IProduct] and [IERC20] Share instance, if any.
     */
    function createProduct(ProductParams memory params) internal virtual override returns (IProduct, IERC20Metadata) {
        TimelockInterestVault vault = new TimelockInterestVault(
            params.owner, params.asset, params.interestRatePercentage, params.interestRateFrequency, params.termPeriod
        );

        return (vault, vault);
    }

    function setUp() public {
        setupAsset();

        ProductParams memory params = ProductParams({
            owner: OWNER,
            asset: _asset,
            interestRatePercentage: INTEREST_RATE_PERCENTAGE,
            interestRateFrequency: FREQUENCY,
            termPeriod: TERM_PERIOD
        });
        (_product, _share) = createProduct(params);

        vm.startPrank(OWNER);
        _asset.transfer(address(_product), USER_ASSET_AMOUNT * 2);
        vm.stopPrank();
    }
}
