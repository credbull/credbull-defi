// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "@credbull/contracts/interfaces/ISimpleInterest.sol";
import { IERC4626Interest } from "@credbull/contracts/interfaces/IERC4626Interest.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract InterestTest is Test {
    uint256 public constant TOLERANCE = 500; // with 18 decimals, means allowed difference of 5E+16
    uint256 public constant NUM_CYCLES_TO_TEST = 2; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    uint256 public constant SCALE = 1 * 10 ** 18; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    using Math for uint256;

    function testInterestToMaxPeriods(uint256 principal, ISimpleInterest simpleInterest) internal {
        uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days

        // due to small fractional numbers, principal needs to be SCALED to calculate correctly
        assertGe(principal, SCALE, "principal not in SCALE");

        // check all periods for 24 months
        for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
            testInterestAtPeriod(principal, simpleInterest, numTimePeriods);
        }
    }

    function testInterestAtPeriod(uint256 principal, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        internal
        virtual
    {
        console2.log("---------------------- simpleInterestTestHarness ----------------------");

        // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
        //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

        uint256 discounted = simpleInterest.calcDiscounted(principal, numTimePeriods);
        uint256 principalFromDiscounted = simpleInterest.calcPrincipalFromDiscounted(discounted, numTimePeriods);

        assertApproxEqAbs(
            principal,
            principalFromDiscounted,
            TOLERANCE,
            assertMsg("principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
        );

        //  discountedFactor = principal - interest, therefore interest = principal - discountedFactor
        assertApproxEqAbs(
            principal - discounted,
            simpleInterest.calcInterest(principal, numTimePeriods),
            10, // even smaller tolerance here
            assertMsg("calcInterest incorrect for ", simpleInterest, numTimePeriods)
        );

        // verify for partial - does it hold that X% of principalFromDiscounted = X% principal
        uint256 discountedPartial = simpleInterest.calcDiscounted(principal.mulDiv(75, 100), numTimePeriods);
        uint256 principalFromDiscountedPartial = simpleInterest.calcPrincipalFromDiscounted(discountedPartial, numTimePeriods);

        assertApproxEqAbs(
            principal.mulDiv(75, 100),
            principalFromDiscountedPartial,
            TOLERANCE,
            assertMsg("partial principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
        );

    }

// these are previews only - vault assets and shares are not updated.   however, it doesn't *actually* deposit or redeem anything!
    function testConvertToAssetAndSharesAtPeriod(uint256 principal, IERC4626Interest vault, uint256 numTimePeriods)
    internal
    virtual
    {
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
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
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
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
        );

        // Perform a partial conversion check (e.g., 33% of the principal)
        uint256 expectedPartialYield = principal.mulDiv(33, 100) + vault.calcInterest(principal.mulDiv(33, 100), vault.getTenor());
        uint256 partialAssetsInWeiAtPeriod =
                            vault.convertToAssetsAtPeriod(sharesInWei.mulDiv(33, 100), numTimePeriods + vault.getTenor());
        assertApproxEqAbs(
            expectedPartialYield,
            partialAssetsInWeiAtPeriod,
            TOLERANCE,
            assertMsg("partial yield does not equal principal + interest", vault, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    // this modifies the assets and shares - it *actually* deposits and redeems
    function testDepositAndRedeemAtPeriod(
        address owner,
        address receiver,
        uint256 principal,
        IERC4626Interest vault,
        uint256 numTimePeriods
    ) internal virtual {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.balanceOf(receiver);
        uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

        // deposit
        vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
        vm.startPrank(receiver);
        assertGe(
            asset.balanceOf(receiver), principal, assertMsg("not enough assets for deposit ", vault, numTimePeriods)
        );
        asset.approve(address(vault), principal); // grant the vault allowance
        uint256 sharesInWei = vault.deposit(principal, receiver); // now deposit
        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + sharesInWei,
            vault.balanceOf(receiver),
            assertMsg("receiver did not receive the correct vault shares ", vault, numTimePeriods)
        );

        // give the vault enough to cover the earned interest

        uint256 interest = vault.calcInterest(principal, vault.getTenor());
        vm.startPrank(owner);
        transferAndAssert(asset, owner, address(vault), interest);
        vm.stopPrank();

        // redeem
        vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // warp the vault to redeem period

        vm.startPrank(receiver);
        uint256 assetsInWei = vault.redeem(sharesInWei, receiver, receiver);
        vm.stopPrank();
        assertApproxEqAbs(
            prevReceiverAssetBalance + interest,
            asset.balanceOf(receiver),
            TOLERANCE,
            assertMsg("receiver did not receive the correct yield", vault, numTimePeriods)
        );

        assertApproxEqAbs(
            principal + interest,
            assetsInWei,
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    function assertMsg(string memory prefix, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        internal
        view
        returns (string memory)
    {
        return string.concat(prefix, toString(simpleInterest), " timePeriod= ", vm.toString(numTimePeriods));
    }

    function toString(ISimpleInterest simpleInterest) internal view returns (string memory) {
        return string.concat(
            " ISimpleInterest [ ",
            " IR = ",
            vm.toString(simpleInterest.getInterestInPercentage()),
            " Freq = ",
            vm.toString(simpleInterest.getFrequency()),
            " ] "
        );
    }

    function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
