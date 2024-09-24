// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IDualRateContext } from "@credbull/interest/IDualRateContext.sol";
import { DualRateContext } from "./DualRateContext.sol";
import { DualRateYieldStrategy } from "./DualRateYieldStrategy.sol";
import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";
import { MultiTokenVault } from "@credbull/interest/nawar/MultiTokenVault.sol";
import { SimpleMultiTokenVault } from "@credbull/interest/nawar/SimpleMultiTokenVault.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Test } from "forge-std/Test.sol";

import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { console2 as console } from "forge-std/console2.sol";

/**
 * @title MultiTokenVaultTest
 * @notice This contract tests various scenarios for the MultiTokenVault and yield strategy implementations.
 * @dev The contract uses the Foundry testing framework and simulates different user actions and redemption events.
 */
contract MultiTokenVaultTest is Test {
    // Declare the ERC20 token used for the vault's operations.
    ERC20 private asset;

    // Scale to match token's decimals (used for precision in calculations).
    uint256 internal SCALE;

    // Ratio used to convert assets to shares, initialized to 1.
    uint256 ASSERT_TO_SHARE_RATIO = 1;

    // The URI used for the ERC1155 token metadata.
    string URI = "https://example.com/token/metadata/{tokenId}.json";

    // Full interest rate used for yield calculation (scaled for decimals).
    uint256 FULL_RATE = 0;

    // Reduced interest rate for the first period of a cycle (scaled for decimals).
    uint256 REDUCED_RATE_FIRST_PERIOD = 0;

    // Reduced interest rate for subsequent periods in a cycle (scaled for decimals).
    uint256 REDUCED_RATE_OTHER_PERIOD = 0;

    // Number of decimal places for the asset.
    uint256 DECIMALS;

    // Number of periods required to complete one full cycle.
    uint256 TENOR = 30;

    // Frequency of the interest calculation, set to yearly by default.
    uint256 FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    // Constant tolerance value used for assertions in tests.
    uint256 public constant TOLERANCE = 1;

    // Maximum value for unsigned integers.
    uint256 MAX_UINT = type(uint256).max;

    // Addresses for the test participants: the owner, Alice, Bob, and the treasury.
    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal treasury = makeAddr("treasury");

    /**
     * @notice Sets up the initial test environment.
     * @dev Initializes the SimpleUSDC token with a supply, sets rates and scales, and transfers assets to Alice and Bob.
     */
    function setUp() public {
        // Set the transaction context to the owner address.
        vm.prank(owner);

        // Initialize the asset as SimpleUSDC with 1 million tokens.
        asset = new SimpleUSDC(1_000_000 ether);

        // Retrieve and store the number of decimals for the asset.
        DECIMALS = asset.decimals();

        // Calculate the scale factor based on the asset's decimals.
        SCALE = 10 ** DECIMALS;

        // Set the full rate to 10% (scaled for decimals).
        FULL_RATE = 10 * SCALE;

        // Set the reduced rate for the first period to 5% (scaled for decimals).
        REDUCED_RATE_FIRST_PERIOD = 5 * SCALE;

        // Set the reduced rate for other periods to 5.5% (scaled for decimals).
        REDUCED_RATE_OTHER_PERIOD = 55 * SCALE / 10;

        // Transfer 100,000 USDC from the owner to Alice.
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        // Transfer 100,000 USDC from the owner to Bob.
        _transferAndAssert(asset, owner, bob, 100_000 * SCALE);
    }

    /**
     * @notice Test Scenario S1: User deposits 1000 USDC and redeems the APY before maturity.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the T-Bill Rate is 5%.
     * - When the user requests to redeem the APY after 15 days.
     * - Then the user should receive the prorated yield of 2.055 USDC.
     * - The principal should remain in the vault.
     *
     * Calculation:
     * - Daily yield rate = 5% / 365 = 0.0137%.
     * - Yield for 15 days = 1000 USDC * 0.0137% * 15 = 2.055 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S1_Scenario() public {
        uint256 fromPeriod = 0;
        uint256 toPeriod = 15;
        uint256 currentPeriod = 0;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log current balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 15th day (period)
        currentPeriod = 15;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her deposit and logs the amount redeemed
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected principal + yield
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S2: User deposits 1000 USDC and redeems the Principal before maturity.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the T-Bill Rate is 5%.
     * - When the user requests to redeem the principal after 20 days.
     * - Then the user should receive their principal of 1000 USDC.
     * - And the prorated yield of 2.74 USDC based on the 5% T-Bill rate.
     *
     * Calculation:
     * - Daily yield rate = 5% / 365 = 0.0137%.
     * - Yield for 20 days = 1000 USDC * 0.0137% * 20 = 2.74 USDC.
     * - Total redemption = 1000 USDC (principal) + 2.74 USDC (yield) = 1002.74 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S2_Scenario() public {
        uint256 fromPeriod = 0;
        uint256 toPeriod = 20;
        uint256 currentPeriod = 0;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 20th day (period)
        currentPeriod = 20;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her deposit and logs the amount redeemed (principal + yield)
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected principal + yield
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S3: User deposits 1000 USDC and redeems the APY after maturity.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the T-Bill Rate is 5% for the first 29 days.
     * - And the APY jumps to 10% on day 30.
     * - When the user requests to redeem the APY after 30 days.
     * - Then the user should receive the yield based on 10% APY, which is 8.22 USDC.
     * - The principal should remain in the vault.
     *
     * Calculation:
     * - Daily yield rate = 10% / 365.
     * - Yield for 30 days = 1000 USDC * (10% / 365) * 30 = 8.22 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S3_Scenario() public {
        uint256 fromPeriod = 0;
        uint256 toPeriod = 30;
        uint256 currentPeriod = 0;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 30th day (period)
        currentPeriod = 30;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her yield after 30 days and logs the amount redeemed
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected yield for 30 days at 10% APY
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S4: User deposits 1000 USDC and redeems the Principal after maturity.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the T-Bill Rate is 5% for the first 29 days.
     * - And the APY jumps to 10% on day 31.
     * - When the user requests to redeem the principal after 30 days.
     * - Then the user should receive their principal of 1000 USDC.
     * - And the yield based on 10% APY, which is 8.22 USDC.
     *
     * Calculation:
     * - Daily yield rate = 10% / 365.
     * - Yield for 30 days = 1000 USDC * (10% / 365) * 30 = 8.22 USDC.
     * - Total redemption = 1000 USDC (principal) + 8.22 USDC (yield) = 1008.22 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S4_Scenario() public {
        uint256 fromPeriod = 1;
        uint256 toPeriod = 31;
        uint256 currentPeriod = 1;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Set the current period to 1 (initial period)
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 31st day (period)
        currentPeriod = 31;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her principal and logs the amount redeemed (principal + yield)
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected principal + yield for 30 days at 10% APY
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S5: User tries to redeem the APY the same day they request redemption.
     *
     * Scenario:
     * - Given a user has deposited USDC into the LiquidStone Plume vault.
     * - And the user has accrued some yield.
     * - When the user requests to redeem the APY.
     * - And attempts to complete the redemption on the same day.
     * - Then the system should not allow the redemption.
     * - The user should be informed that a one-day notice is required for APY redemption.
     *
     * Expected behavior:
     * - The system should prevent the redemption from occurring on the same day.
     * - Appropriate error or revert message should be displayed, indicating that a one-day notice is required.
     */
    function SKIP_test__MultiTokenERC1155VaulTest__S5_Scenario() public {
        // To do with request to redeem
        // Placeholder for the scenario where the user attempts to redeem APY on the same day as the request.
        // The system should not allow this redemption due to a one-day notice requirement.
        console.log("User tries to redeem the APY on the same day as the request.");

        // The expected behavior is that the redemption is not allowed and a relevant message or revert occurs.
        console.log("The system should reject the redemption and inform the user about the one-day notice requirement.");
    }

    /**
     * @notice Test Scenario S6: User tries to redeem the Principal the same day they request redemption.
     *
     * Scenario:
     * - Given a user has deposited USDC into the LiquidStone Plume vault.
     * - And the user has accrued some yield.
     * - When the user requests to redeem the Principal.
     * - And attempts to complete the redemption on the same day.
     * - Then the system should not allow the redemption.
     * - The user should be informed that a one-day notice is required for Principal redemption.
     *
     * Expected behavior:
     * - The system should prevent the redemption of the Principal on the same day.
     * - Appropriate error or revert message should be displayed, indicating that a one-day notice is required for Principal redemption.
     */
    function SKIP_test__MultiTokenERC1155VaulTest__S6_Scenario() public {
        // To do with request to redeem the principal
        // Placeholder for the scenario where the user attempts to redeem the Principal on the same day as the request.
        // The system should not allow this redemption due to a one-day notice requirement.
        console.log("User tries to redeem the Principal on the same day as the request.");

        // The expected behavior is that the redemption is not allowed and a relevant message or revert occurs.
        console.log(
            "The system should reject the redemption and inform the user about the one-day notice requirement for Principal redemption."
        );
    }

    /**
     * @notice Test Scenario S7: User deposits 1000 USDC, retains for extra cycle, redeems the APY before the new cycle ends.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the user has completed one full 30-day cycle.
     * - And the T-Bill Rate for the first cycle was 5%.
     * - And the T-Bill Rate for the second cycle is 5.5%.
     * - When the user requests to redeem the APY after 45 days (15 days into the second cycle).
     * - Then the user should receive the yield from the first cycle (8.22 USDC).
     * - And the prorated yield from the second cycle (2.26 USDC).
     * - The principal should remain in the vault.
     *
     * Calculation:
     * - Yield for the first cycle at 5% APY = 1000 USDC * (5% / 365) * 30 = 8.22 USDC.
     * - Prorated yield for 15 days of the second cycle at 5.5% APY = 1000 USDC * (5.5% / 365) * 15 = 2.26 USDC.
     * - Total redemption = 8.22 USDC (first cycle) + 2.26 USDC (second cycle) = 10.48 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S7_Scenario() public {
        uint256 fromPeriod = 0;
        uint256 toPeriod = 45;
        uint256 currentPeriod = 0;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 45th day (15 days into the second cycle)
        currentPeriod = 45;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her APY and logs the amount redeemed (first cycle + prorated second cycle yield)
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected yield from the first cycle and prorated yield from the second cycle
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S8: User deposits 1000 USDC, retains for an extra cycle, and redeems the Principal before the new cycle ends.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the user has completed one full 30-day cycle.
     * - And the T-Bill Rate for the first cycle was 5%.
     * - And the T-Bill Rate for the second cycle is 5.5%.
     * - When the user requests to redeem the Principal after 50 days (20 days into the second cycle).
     * - Then the user should receive their principal of 1000 USDC.
     * - And the yield from the first cycle (8.22 USDC).
     * - And the prorated yield from the second cycle (3.01 USDC).
     *
     * Calculation:
     * - First cycle yield (30 days at 5% APY) = 1000 USDC * (5% / 365) * 30 = 8.22 USDC.
     * - Second cycle partial yield (20 days at 5.5% APY) = 1000 USDC * (5.5% / 365) * 20 = 3.01 USDC.
     * - Total redemption = 1000 USDC (principal) + 8.22 USDC (first cycle yield) + 3.01 USDC (second cycle yield) = 1011.23 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S8_Scenario() public {
        uint256 fromPeriod = 0;
        uint256 toPeriod = 50;
        uint256 currentPeriod = 0;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 50th day (20 days into the second cycle)
        currentPeriod = 50;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her Principal and logs the amount redeemed (principal + first cycle yield + prorated second cycle yield)
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected principal + first cycle yield + prorated second cycle yield
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S9: User deposits 1000 USDC, retains for an extra cycle, and redeems the APY after the new cycle ends.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the user has completed two full 30-day cycles.
     * - And the T-Bill Rate for the first cycle was 5%.
     * - And the T-Bill Rate for the second cycle was 5.5%.
     * - When the user requests to redeem the APY after 60 days.
     * - Then the user should receive the yield from the first cycle (8.22 USDC).
     * - And the yield from the second cycle (8.22 USDC).
     * - The principal should remain in the vault.
     *
     * Calculation:
     * - First cycle yield (30 days at 5% APY) = 1000 USDC * (5% / 365) * 30 = 8.22 USDC.
     * - Second cycle yield (30 days at 5.5% APY) = 1000 USDC * (5.5% / 365) * 30 = 8.22 USDC.
     * - Total yield = 8.22 USDC (first cycle) + 8.22 USDC (second cycle) = 16.44 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S9_Scenario() public {
        uint256 fromPeriod = 0;
        uint256 toPeriod = 60;
        uint256 currentPeriod = 0;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 60th day (end of the second cycle)
        currentPeriod = 60;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her APY and logs the amount redeemed (first and second cycle yields)
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected yield from both cycles (16.44 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * @notice Test Scenario S10: User deposits 1000 USDC, retains for an extra cycle, and redeems the Principal after the new cycle ends.
     *
     * Scenario:
     * - Given a user has deposited 1000 USDC into the LiquidStone Plume vault.
     * - And the user has completed two full 30-day cycles.
     * - And the T-Bill Rate for the first cycle was 5%.
     * - And the T-Bill Rate for the second cycle was 5.5%.
     * - When the user requests to redeem the Principal after 60 days.
     * - Then the user should receive their principal of 1000 USDC.
     * - And the yield from the first cycle (8.22 USDC).
     * - And the yield from the second cycle (8.22 USDC).
     *
     * Calculation:
     * - First cycle yield (30 days at 5% APY) = 1000 USDC * (5% / 365) * 30 = 8.22 USDC.
     * - Second cycle yield (30 days at 5.5% APY) = 1000 USDC * (5.5% / 365) * 30 = 8.22 USDC.
     * - Total redemption = 1000 USDC (Principal) + 8.22 USDC (First cycle yield) + 8.22 USDC (Second cycle yield) = 1016.44 USDC.
     */
    function test__MultiTokenERC1155VaulTest__S10_Scenario() public {
        uint256 fromPeriod = 1;
        uint256 toPeriod = 61;
        uint256 currentPeriod = 1;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing purposes
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Set the current period in the vault
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        // Get the current deposit period for Alice's deposit
        uint256 depositPeriod = vault.getCurrentTimePeriodsElapsed();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        console.log("depositPeriod = ", depositPeriod);

        // Log the initial balances of Owner and Alice
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Alice deposits 1000 USDC into the vault
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));

        // Log the balance of the treasury and vault after the deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to the 61st day (end of the second cycle)
        currentPeriod = 61;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her principal and logs the amount redeemed (principal + yield from two cycles)
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, depositPeriod), alice, alice, depositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the final balance of the vault after redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected principal + yield from two cycles (1016.44 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, depositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );
    }

    /**
     * # ================================================
     * # Scenarios below are for Multiple Users (MU-#)
     * # ================================================
     */

    /**
     * @notice Test Scenario MU-1: Two users deposit at different funding rounds and both redeem on day 31.
     *
     * Scenario:
     * - Given User A deposits 1000 USDC on day 1.
     * - And User B deposits 1000 USDC on day 15.
     * - And the T-Bill Rate is 5%.
     * - When both users redeem their investments on day 31.
     * - Then User A should receive 10% APY on their investment.
     * - And User B should receive 5% APY on their investment.
     *
     * Calculation:
     * - User A redemption = 1000 + (1000 * 10% * 30/365) = 1008.22 USDC.
     * - User B redemption = 1000 + (1000 * 5% * 15/365) = 1002.05 USDC.
     */
    function test__MultiTokenERC1155VaulTest__MU_1_Scenario() public {
        uint256 fromPeriod = 1;
        uint256 toPeriod = 31;
        uint256 currentPeriod = 1;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing purposes
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Set the current period in the vault
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        // Log the initial balances of Owner, Alice, and Bob
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));
        console.log("Bob balance = ", asset.balanceOf(bob));

        // Alice deposits 1000 USDC on day 1
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        uint256 aliceDepositPeriod = vault.getCurrentTimePeriodsElapsed();
        console.log("aliceDepositPeriod = ", aliceDepositPeriod);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));
        console.log("Bob balance = ", asset.balanceOf(bob));

        // Log the balance of the treasury and vault after Alice's deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to day 15 and Bob deposits 1000 USDC
        currentPeriod = 15;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        vm.startPrank(bob);
        asset.approve(address(vault), asset.balanceOf(bob));
        vault.deposit(principal, bob);
        uint256 bobDepositPeriod = vault.getCurrentTimePeriodsElapsed();
        console.log("bobDepositPeriod = ", bobDepositPeriod);
        vm.stopPrank();

        // Advance to day 31 and both users redeem their investments
        currentPeriod = 31;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her investment and logs the amount redeemed
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, aliceDepositPeriod), alice, alice, aliceDepositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the balance of the vault after Alice's redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected amount (1008.22 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, aliceDepositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );

        // Update context for Bob's redemption on day 31 (accounting for his deposit on day 15)
        DualRateContext(contextAddress).setFromPeriod(15);

        // Bob redeems his investment and logs the amount redeemed
        vm.startPrank(bob);
        redeemed = vault.redeemForDepositPeriod(vault.balanceOf(bob, bobDepositPeriod), bob, bob, bobDepositPeriod);
        console.log("Bob redeemed = ", redeemed);
        vm.stopPrank();

        // Log the balance of the vault after Bob's redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Bob's redeemed amount matches the expected amount (1002.05 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, bobDepositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at partialTenor period"
        );
    }

    /**
     * @notice Test Scenario MU-2: Two users deposit at different funding rounds and both redeem 15 days after day 31.
     *
     * Scenario:
     * - Given User A deposits 1000 USDC on day 1.
     * - And User B deposits 1000 USDC on day 15.
     * - And the T-Bill Rate is 5% for the first cycle.
     * - And the T-Bill Rate is 5.5% for the second cycle.
     * - When both users redeem their investments 15 days after day 31.
     * - Then User A should receive 10% APY for the first 30 days and 5.5% for the next 15 days.
     * - And User B should receive 10% APY for the full 30 days.
     *
     * Calculation:
     * - User A redemption = 1000 + (1000 * 10% * 30/365) + (1000 * 5.5% * 15/365) = 1010.48 USDC.
     * - User B redemption = 1000 + (1000 * 10% * 30/365) = 1008.22 USDC.
     */
    function test__MultiTokenERC1155VaulTest__MU_2_Scenario() public {
        uint256 fromPeriod = 1;
        uint256 toPeriod = 46;
        uint256 currentPeriod = 1;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing purposes
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Set the current period in the vault
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        // Log the initial balances of Owner, Alice, and Bob
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));
        console.log("Bob balance = ", asset.balanceOf(bob));

        // Alice deposits 1000 USDC on day 1
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        uint256 aliceDepositPeriod = vault.getCurrentTimePeriodsElapsed();
        console.log("aliceDepositPeriod = ", aliceDepositPeriod);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));
        console.log("Bob balance = ", asset.balanceOf(bob));

        // Log the balance of the treasury and vault after Alice's deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to day 15 and Bob deposits 1000 USDC
        currentPeriod = 15;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        vm.startPrank(bob);
        asset.approve(address(vault), asset.balanceOf(bob));
        vault.deposit(principal, bob);
        uint256 bobDepositPeriod = vault.getCurrentTimePeriodsElapsed();
        console.log("bobDepositPeriod = ", bobDepositPeriod);
        vm.stopPrank();

        // Advance to day 46 and both users redeem their investments
        currentPeriod = 46;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her investment and logs the amount redeemed
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, aliceDepositPeriod), alice, alice, aliceDepositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the balance of the vault after Alice's redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected amount (1010.48 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, aliceDepositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );

        // Update context for Bob's redemption on day 46 (accounting for his deposit on day 15)
        DualRateContext(contextAddress).setFromPeriod(15);

        // Bob redeems his investment and logs the amount redeemed
        vm.startPrank(bob);
        redeemed = vault.redeemForDepositPeriod(vault.balanceOf(bob, bobDepositPeriod), bob, bob, bobDepositPeriod);
        console.log("Bob redeemed = ", redeemed);
        vm.stopPrank();

        // Log the balance of the vault after Bob's redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Bob's redeemed amount matches the expected amount (1008.22 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, bobDepositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at partialTenor period"
        );
    }

    /**
     * @notice Test Scenario MU-3: Two users deposit at different funding rounds with different T-Bill rates, both redeem 14 days after day 31.
     *
     * Scenario:
     * - Given User A deposits 1000 USDC on day 1.
     * - And User B deposits 1000 USDC on day 15.
     * - And the T-Bill Rate is 5% from day 1 to day 20.
     * - And the T-Bill Rate is 5.5% from day 20 to day 45.
     * - When both users redeem their investments on day 45.
     * - Then User A should receive 1010.33 USDC.
     * - And User B should receive 1004.30 USDC.
     *
     * Calculation:
     * - User A:
     *   - First 30 days yield (10% APY) = 1000 * (10% / 365) * 30 = 8.22 USDC.
     *   - Remaining 14 days yield (5.5% APY) = 1000 * (5.5% / 365) * 14 = 2.11 USDC.
     *   - Total yield = 8.22 + 2.11 = 10.33 USDC.
     *   - Total redemption = 1000 + 10.33 = 1010.33 USDC.
     *
     * - User B:
     *   - First 5 days yield (5% APY) = 1000 * (5% / 365) * 5 = 0.68 USDC.
     *   - Next 24 days yield (5.5% APY) = 1000 * (5.5% / 365) * 24 = 3.62 USDC.
     *   - Total yield = 0.68 + 3.62 = 4.30 USDC.
     *   - Total redemption = 1000 + 4.30 = 1004.30 USDC.
     */
    function SKIP_test__MultiTokenERC1155VaulTest__MU_3_Scenario() public {
        uint256 fromPeriod = 1;
        uint256 toPeriod = 45;
        uint256 currentPeriod = 1;
        uint256 principal = 1000 * SCALE;

        // Refill the treasury with half of the owner's balance for testing purposes
        uint256 amountToRefillTreasury = asset.balanceOf(owner) / 2;
        _refillTreasury(amountToRefillTreasury);

        // Initialize the yield strategy and context for dual-rate yield calculation
        IYieldStrategy yieldStrategy = new DualRateYieldStrategy();
        IDualRateContext multiRateContext = new DualRateContext(
            FULL_RATE,
            REDUCED_RATE_FIRST_PERIOD,
            REDUCED_RATE_OTHER_PERIOD,
            fromPeriod,
            toPeriod,
            FREQUENCY,
            TENOR,
            DECIMALS
        );
        address contextAddress = address(multiRateContext);

        // Initialize the vault contract
        MultiTokenVault vault = new SimpleMultiTokenVault(
            treasury, asset, URI, yieldStrategy, multiRateContext, ASSERT_TO_SHARE_RATIO, owner
        );

        // Approve the vault to spend treasury assets
        vm.startPrank(treasury);
        asset.approve(address(vault), MAX_UINT);
        vm.stopPrank();

        // Log the initial balances of Owner, Alice, and Bob
        console.log("Owner balance = ", asset.balanceOf(owner));
        console.log("Alice balance = ", asset.balanceOf(alice));
        console.log("Bob balance = ", asset.balanceOf(bob));

        // Alice deposits 1000 USDC on day 1
        vm.startPrank(alice);
        asset.approve(address(vault), asset.balanceOf(alice));
        vault.deposit(principal, alice);
        uint256 aliceDepositPeriod = vault.getCurrentTimePeriodsElapsed();
        console.log("aliceDepositPeriod = ", aliceDepositPeriod);
        vm.stopPrank();

        // Log Alice's balance after the deposit
        console.log("Alice balance = ", asset.balanceOf(alice));
        console.log("Bob balance = ", asset.balanceOf(bob));

        // Log the balance of the treasury and vault after Alice's deposit
        console.log("Treasury balance = ", asset.balanceOf(treasury));
        console.log("Vault balance = ", vault.getTotalBalance());

        // Advance to day 15 and Bob deposits 1000 USDC
        currentPeriod = 15;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        vm.stopPrank();

        vm.startPrank(bob);
        asset.approve(address(vault), asset.balanceOf(bob));
        vault.deposit(principal, bob);
        uint256 bobDepositPeriod = vault.getCurrentTimePeriodsElapsed();
        console.log("bobDepositPeriod = ", bobDepositPeriod);
        vm.stopPrank();

        // Advance to day 45 and both users redeem their investments
        currentPeriod = 45;
        vm.startPrank(owner);
        vault.setCurrentTimePeriodsElapsed(currentPeriod);
        uint256 redeemPeriod = vault.getCurrentTimePeriodsElapsed();
        vm.stopPrank();

        // Alice redeems her investment and logs the amount redeemed
        vm.startPrank(alice);
        uint256 redeemed =
            vault.redeemForDepositPeriod(vault.balanceOf(alice, aliceDepositPeriod), alice, alice, aliceDepositPeriod);
        console.log("Alice redeemed = ", redeemed);
        vm.stopPrank();

        // Log the balance of the vault after Alice's redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Alice's redeemed amount matches the expected amount (1010.33 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, aliceDepositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at fullTenor period"
        );

        // Update context for Bob's redemption on day 45 (accounting for his deposit on day 15)
        DualRateContext(contextAddress).setFromPeriod(15);

        // Bob redeems his investment and logs the amount redeemed
        vm.startPrank(bob);
        redeemed = vault.redeemForDepositPeriod(vault.balanceOf(bob, bobDepositPeriod), bob, bob, bobDepositPeriod);
        console.log("Bob redeemed = ", redeemed);
        vm.stopPrank();

        // Log the balance of the vault after Bob's redemption
        console.log("Vault balance = ", vault.getTotalBalance());

        // Validate that Bob's redeemed amount matches the expected amount (1004.30 USDC)
        assertApproxEqAbs(
            redeemed,
            principal + yieldStrategy.calcYield(contextAddress, principal, bobDepositPeriod, redeemPeriod),
            TOLERANCE,
            "yield wrong at partialTenor period"
        );
    }

    /**
     * @notice Internal function to refill the treasury with a specified amount of assets.
     * @dev This function transfers a given amount of assets from the owner's balance to the treasury.
     * @param amount The amount of assets to transfer to the treasury.
     */
    function _refillTreasury(uint256 amount) internal {
        // Start simulating owner actions
        vm.startPrank(owner);
        // Transfer the specified amount from the owner to the treasury
        asset.transfer(treasury, amount);
        // Stop simulating owner actions
        vm.stopPrank();

        // Log the refill action for debugging purposes
        console.log("Treasury refilled with amount:", amount);
    }

    /**
     * @notice Internal function to transfer tokens from one address to another and verify the balance.
     * @dev This function transfers the specified amount of tokens from the fromAddress to the toAddress and asserts that the balance is updated correctly.
     * @param _token The ERC20 token to be transferred.
     * @param fromAddress The address from which the tokens will be transferred.
     * @param toAddress The address to which the tokens will be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function _transferAndAssert(ERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        // Get the balance of the recipient before the transfer
        uint256 beforeBalance = _token.balanceOf(toAddress);

        // Start simulating actions from the fromAddress
        vm.startPrank(fromAddress);
        // Transfer the specified amount of tokens from fromAddress to toAddress
        _token.transfer(toAddress, amount);
        // Stop simulating actions from the fromAddress
        vm.stopPrank();

        // Assert that the toAddress balance increased by the expected amount
        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));

        // Log the final balance for confirmation
        console.log("Balance after transfer:", _token.balanceOf(toAddress));
    }
}
