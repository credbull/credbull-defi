// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { console2 as console } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { IProduct } from "@credbull-spike/contracts/IProduct.sol";
import { SimpleUSDC } from "@credbull-spike/contracts/SimpleUSDC.sol";

import { ITimelock } from "@credbull-spike/contracts/ian/interfaces/ITimelock.sol";

import { SimpleInterestVault } from "@credbull-spike/contracts/ian/fixed/SimpleInterestVault.sol";
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
     */
    function createProduct(ProductParams memory params) internal virtual override returns (IProduct) {
        return new TimelockInterestVault(
            params.owner, params.asset, params.interestRatePercentage, params.interestRateFrequency, params.tenor
        );
    }

    function setUp() public {
        scenarioSetup();

        TimelockInterestVault vault =
            new TimelockInterestVault(OWNER, _asset, INTEREST_RATE_PERCENTAGE, FREQUENCY, TENOR);

        _product = vault;
        _share = vault;

        vm.startPrank(OWNER);
        _asset.transfer(address(_product), USER_ASSET_AMOUNT * 2);
        vm.stopPrank();
    }
}
