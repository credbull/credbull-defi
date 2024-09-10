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

/**
 * @title Short Term Fixed Yield Vault Scenario Tests
 * @author credbull
 * @notice This is the product proving tests whereby the specification has been converted to tests.
 */
abstract contract ProductScenarioTest is Test {
    using Math for uint256;

    address internal immutable OWNER = makeAddr("owner");
    address internal immutable ALICE = makeAddr("alice");
    address internal immutable BOB = makeAddr("bob");

    uint8 internal constant INTEREST_RATE_PERCENTAGE = 12;
    uint16 internal constant FREQUENCY = 360;
    uint8 internal constant TENOR = 30;

    uint256 internal constant ASSET_SUPPLY = 10_000_000 ether;
    uint256 internal constant USER_ASSET_AMOUNT = 100_000 ether;

    IERC20Metadata internal _asset;
    IERC20 internal _share;
    IProduct internal _product;

    // NOTE (JL,2024-09-10): This struct & factory function may not work.
    struct ProductParams {
        address owner;
        IERC20Metadata asset;
        uint8 interestRatePercentage;
        uint16 interestRateFrequency;
        uint8 tenor;
    }

    /**
     * @dev Creates an instance of the [IProduct] under test, using the `params` configuration.
     *
     * @param params The [ProductParams] of configuration for the [IProduct].
     */
    function createProduct(ProductParams memory params) internal virtual returns (IProduct);

    /**
     * @dev A utility setup function intended to be invoked by the `setUp` function of the realising [Test].
     */
    function scenarioSetup() internal {
        vm.startPrank(OWNER);
        _asset = new SimpleUSDC(ASSET_SUPPLY);
        vm.stopPrank();
        assertEq(_asset.balanceOf(OWNER), ASSET_SUPPLY, "owner should start with total supply");

        vm.startPrank(OWNER);
        _asset.transfer(ALICE, USER_ASSET_AMOUNT);
        _asset.transfer(BOB, USER_ASSET_AMOUNT);
        vm.stopPrank();
    }

    /**
     * Scenario: User invests USDC
     *   Given the vault is open
     *   When a user deposits 10,000 USDC into the contract
     *   Then their investment of 10,000 USDC should be accepted
     *   And they should receive a confirmation of their 10,000 USDC investment
     */
    function SKIP_test_Scenario_UserInvestsUsdc() public {
        uint256 depositAmount = 10_000 ether;

        vm.startPrank(ALICE);
        _asset.approve(address(_product), depositAmount);
        uint256 _shares = _product.deposit(depositAmount, ALICE);
        vm.stopPrank();

        assertNotEq(0, _shares, "No _shares were allocated");
        assertEq(_shares, _share.balanceOf(ALICE), "Incorrect number of _shares allocated to Alice");

        // NOTE (JL,2024-09-04): Confirmation is deemed to be the succesful Shares allocation.
    }

    /**
     * Scenario: User attempts to invest in a closed vault
     *   Given the vault is closed
     *   When a user tries to deposit 5,000 USDC into the contract
     *   Then their investment of 5,000 USDC should be rejected
     */
    function SKIP_test_Scenario_UserAttemptsInvestClosedVault() public {
        uint256 depositAmount = 5_000 ether;

        vm.startPrank(OWNER);
        // NOTE (JL,2024-09-04): We will using Paused/Unpaused as the Open/Closed indicator.
        // vault.pause();
        vm.stopPrank();

        vm.startPrank(ALICE);
        _asset.approve(address(_product), depositAmount);

        vm.expectRevert(Pausable.EnforcedPause.selector);
        _product.deposit(depositAmount, ALICE);
        vm.stopPrank();
    }

    /**
     * Scenario: User tries to withdraw before the lock period ends
     *   Given a user has an active investment of 20,000 USDC
     *   And the lock period has not ended
     *   When the user attempts to withdraw their 20,000 USDC
     *   Then the withdrawal should be denied
     *
     * DEMO Flow A2
     */
    function test_Scenario_UserAttemptsWithdrawalBeforeEndOfLockPeriod() public {
        uint256 depositAmount = 20_000 ether;

        vm.startPrank(ALICE);
        _asset.approve(address(_product), depositAmount);
        uint256 _shares = _product.deposit(depositAmount, ALICE);
        vm.stopPrank();

        // Advance the periods elapsed, but to less than the Tenor, so lock period still in effect.
        uint256 currentPeriod = _product.getCurrentTimePeriodsElapsed();
        uint256 elapsedPeriods = currentPeriod + (TENOR / 2);
        _product.setCurrentTimePeriodsElapsed(elapsedPeriods);

        vm.startPrank(ALICE);
        vm.expectRevert();
        _product.redeem(_shares, ALICE, ALICE);
        vm.stopPrank();
    }

    /**
     * Scenario: User withdraws after the lock period
     *   Given a user has an active investment of 15,000 USDC
     *   And the lock period of 30 days has ended
     *   When the user withdraws their funds
     *   Then they should receive 15,075 USDC (15,000 + 75 USDC interest, equivalent to 6.0% APY)
     *
     * DEMO Flow A3
     */
    function test_Scenario_Term30_UserWithdrawsAfterLockPeriod() public {
        uint256 depositAmount = 15_000 ether;

        vm.startPrank(ALICE);
        _asset.approve(address(_product), depositAmount);
        uint256 _shares = _product.deposit(depositAmount, ALICE);
        vm.stopPrank();

        _product.setCurrentTimePeriodsElapsed(TENOR);

        vm.startPrank(ALICE);
        uint256 redeemed = _product.redeem(_shares, ALICE, ALICE);
        vm.stopPrank();

        // NOTE (JL,2024-09-09): Returns adjused for the 12% APY in effect.
        uint256 expectedRedeemed = 15_150 ether;
        assertNotEq(0, redeemed, "No _assets were redeemed");
        assertGt(redeemed, depositAmount, "Incorrect number of _assets redeemed");
        assertEq(expectedRedeemed, redeemed, "Incorrect number of _assets redeemed");
    }

    /**
     * Scenario: User rolls over their investment
     *   Given a user has an active investment of 25,000 USDC
     *   And the lock period of 30 days has ended
     *   When the user chooses not to withdraw
     *   Then their investment should automatically roll over to 25,000 USDC
     *   And they should receive an additional 1% bonus on their yield for the next period
     */
    function SKIP_test_Scenario_Term30_UserRollsOverInvestment() public { }

    /**
     * Scenario: Calculating returns for a standard investment
     *   Given a user has invested 50,000 USDC for exactly 30 days
     *   When the returns are calculated
     *   Then the user should receive 50,250 USDC (50,000 + 250 USDC interest, exactly 6.0% APY)
     */
    function SKIP_test_Scenario_Term30_StandardInvestmentReturnsAreCorrect() public { }

    /**
     * Scenario: Calculating returns for a rolled-over investment
     *   Given a user has invested 40,000 USDC for 60 days (initial 30 days + 30 days rollover, 6% APY)
     *   When the returns are calculated
     *   Then the user should receive 40,600 USDC (40,000 + 401 USDC standard interest + 33.5 USDC rollover bonus)
     *
     * DEMO Flow B1
     */
    function DISABLED_test_Scenario_Term30_RolloverInvestmentReturnsAreCorrect() public {
        uint256 depositAmount = 40_000 ether;

        vm.startPrank(ALICE);
        _asset.approve(address(_product), depositAmount);
        uint256 _shares = _product.deposit(depositAmount, ALICE);
        vm.stopPrank();

        // Advance the periods elapsed, but to less than the Tenor, so lock period still in effect.
        uint256 elapsedPeriods = TENOR * 2;
        _product.setCurrentTimePeriodsElapsed(elapsedPeriods);

        vm.startPrank(ALICE);
        uint256 redeemed = _product.redeem(_shares, ALICE, ALICE);
        vm.stopPrank();

        // NOTE (JL,2024-09-09): Returns adjused for the 12% APY in effect.
        uint256 expectedRedeemed = 41_200 ether;
        assertNotEq(0, redeemed, "No _assets were redeemed");
        assertGt(redeemed, depositAmount, "Incorrect number of _assets redeemed");
        assertEq(expectedRedeemed, redeemed, "Incorrect number of _assets redeemed");
    }

    /**
     * Scenario: User partially rolls over their investment
     *   Given a user has an active investment of 100,000 USDC
     *   And the lock period of 30 days (6.0% APY) has ended
     *   And their total balance including interest is 100,500 USDC (100,000 + 500 USDC interest)
     *   When the user chooses to withdraw 60,000 USDC
     *   And roll over the remaining amount
     *   Then the user should receive 60,000 USDC in their wallet
     *   And 40,500 USDC should be rolled over into a new 30-day period
     *   And the rolled-over amount should be eligible for the 1% bonus
     *   And after the next 30-day period, assuming the same 6.0% APY:
     *   The standard interest on 40,500 USDC should be 202.5 USDC
     *   The 1% rollover bonus should be 33.75 USDC
     *   The total balance after the second period should be 40,736.25 USDC
     *
     * DEMO Flow C1
     */
    function test_Scenario_Term30_UserWithdrawsPartialAndRollsOverRemainder() public { }

    /**
     * Scenario: Viewing investment details
     *   Given a user has an active investment of 35,000 USDC (6.0% APY, 30 day lock) for 15 days
     *   When they request to view their investment details
     *   Then they should see:
     *     Invested amount: 35,000 USDC
     *     Current yield: 87.5 USDC (half of the 30-day yield)
     *     Remaining lock time: 15 days
     *
     * DEMO Flow A1
     */
    function test_Scenario_Term30_UserViewsInvestment() public { }

    /**
     * Scenario: Calculating returns for a standard 90-day investment
     *   Given a user has invested 200,000 USDC for exactly 90 days
     *   When the returns are calculated
     *   Then the user should receive 204,000 USDC (200,000 + 4,000 USDC interest, exactly 8.0% APY for 90 days)
     */
    function SKIP_test_Scenario_Term90_StandardInvestmentReturnsAreCorrect() public { }

    /**
     * Scenario: Viewing investment details with new terms
     *   Given a user has an active investment of 150,000 USDC (8.0% APY, 90 day lock) for 45 days
     *   When they request to view their investment details
     *   Then they should see:
     *     Invested amount: 150,000 USDC
     *     Current yield: 1,500 USDC (half of the 90-day yield)
     *     Remaining lock time: 45 days
     */
    function SKIP_test_Scenario_Term90_UserViewsInvestment() public { }

    /**
     * Scenario: User rolls over their investment with new terms
     *   Given a user has an active investment of 300,000 USDC
     *   And the 90-day lock (8% APY) period has ended
     *   When the user chooses not to withdraw
     *   Then their investment should automatically roll over to 300,000 USDC for another 90 days
     *   And they should receive an additional 1% bonus on their yield for the next period
     *   And after the next 90-day period:
     *     The standard interest on 300,000 USDC should be 6,000 USDC (8.0% APY for 90 days)
     *     The 1% rollover bonus should be 750 USDC
     *     The total balance after the second period should be 306,750 USDC
     */
    function SKIP_test_Scenario_Term90_UserRollsOverWithNewTerms() public { }
}
