// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "./ISimpleInterest.s.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { IERC4626Interest } from "./IERC4626Interest.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { InterestTest } from "./InterestTest.t.sol";
import { TimelockInterestVault } from "./TimelockInterestVault.s.sol";

contract TimelockInterestVaultTest is InterestTest {
    IERC20 private asset;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    function setUp() public {
        uint256 tokenSupply = 100000 ether;

        vm.startPrank(owner);
        asset = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 10000 ether;

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, owner, alice, userTokenAmount);
        transferAndAssert(asset, owner, bob, userTokenAmount);
    }

    function test__TimelockInterestVaultTest__Daily() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        TimelockInterestVault vault = new TimelockInterestVault(owner, asset, apy, frequencyValue, tenor);

        // check principal and interest calcs
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
