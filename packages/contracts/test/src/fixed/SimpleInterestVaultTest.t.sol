// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IERC4626Interest } from "@test/src/fixed/IERC4626Interest.s.sol";
import { SimpleInterestVault } from "@test/src/fixed/SimpleInterestVault.s.sol";
import { Frequencies } from "@test/src/fixed/Frequencies.s.sol";

import { InterestTest } from "@test/src/fixed/InterestTest.t.sol";
import { ISimpleInterest } from "@test/src/interfaces/ISimpleInterest.s.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SimpleInterestVaultTest is InterestTest {
    using Math for uint256;

    IERC20 private asset;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    function setUp() public {
        uint256 tokenSupply = 1000000 ether; // 1 million

        vm.startPrank(owner);
        asset = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 100000 ether; // 100,000 each

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, owner, alice, userTokenAmount);
        transferAndAssert(asset, owner, bob, userTokenAmount);
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
        super.testConvertToAssetAndSharesAtPeriod(principal, vault, numTimePeriods); // previews only
        super.testDepositAndRedeemAtPeriod(owner, alice, principal, vault, numTimePeriods); // actual deposits/redeems
    }
}
