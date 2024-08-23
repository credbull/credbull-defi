// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC4626Interest } from "./IERC4626Interest.s.sol";
import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { InterestTest } from "./InterestTest.t.sol";
import { ISimpleInterest } from "./ISimpleInterest.s.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

contract SimpleInterestVaultTest is InterestTest {
    using Math for uint256;

    IERC20 private asset;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");

    function setUp() public {
        uint256 tokenSupply = 100000 ether;

        vm.startPrank(owner);
        asset = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 1000 ether;

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, owner, alice, userTokenAmount);
        transferAndAssert(asset, owner, bob, userTokenAmount);
        transferAndAssert(asset, owner, charlie, userTokenAmount);
    }

    function test__SimpleInterestVaultTest__CheckScale() public {
        uint256 apy = 10; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 90;

        IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

        uint256 scaleMinus1 = SCALE - 1;

        assertEq(0, vault.convertToAssets(scaleMinus1), "convert to assets not scaled");

        assertEq(0, vault.convertToShares(scaleMinus1), "convert to shares not scaled");
    }

    function test__SimpleInterestVaultTest__Monthly() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
        uint256 tenor = 3;

        IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

        testInterestToMaxPeriods(200 * SCALE, vault);
    }

    function test__SimpleInterestVaultTest__Daily360() public {
        uint256 apy = 10; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 90;

        IERC4626Interest vault = new SimpleInterestVault(asset, apy, frequencyValue, tenor);

        testInterestToMaxPeriods(200 * SCALE, vault);
    }

    function testInterestAtPeriod(uint256 principal, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        internal
        override
    {
        // test against the simple interest harness
        super.testInterestAtPeriod(principal, simpleInterest, numTimePeriods);

        // test the vault related
        IERC4626Interest vault = (IERC4626Interest)(address(simpleInterest));

        uint256 expectedYield = principal + vault.calcInterest(principal, vault.getTenor());

        // check convertAtSharesAtPeriod and convertToAssetsAtPeriod

        // yieldAt(Periods+Tenor) = principalAtDeposit + interestForTenor - similar to how we test the interest.
        uint256 sharesInWeiAtPeriod = vault.convertToSharesAtPeriod(principal, numTimePeriods);
        uint256 assetsInWeiAtPeriod =
            vault.convertToAssetsAtPeriod(sharesInWeiAtPeriod, numTimePeriods + vault.getTenor());

        assertApproxEqAbs(
            expectedYield,
            assetsInWeiAtPeriod,
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", simpleInterest, numTimePeriods)
        );

        // check convertAtShares and convertToAssets -- simulates the passage of time (e.g. block times)
        uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();

        vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
        uint256 sharesInWei = vault.convertToShares(principal); // now deposit

        vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // set redeem numTimePeriods
        uint256 assetsInWei = vault.convertToAssets(sharesInWei); // now redeem

        assertApproxEqAbs(
            principal + vault.calcInterest(principal, vault.getTenor()),
            assetsInWei,
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", simpleInterest, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }
}
