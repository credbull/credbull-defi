// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterestTest.t.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At interestFrequency 1, 1 asset gives 1 / APY shares
// - At interestFrequency 2, 1 asset gives 1 / (2 * APY) shares,
// - and so on...
//
// This is like having linear deflation over time.
contract SimpleInterestVault is ERC4626 {
    using Math for uint256;

    SimpleInterest private simpleInterest;
    uint256 public currentInterestFrequency; // the current interest frequency

    constructor(IERC20 asset, SimpleInterest _simpleInterest)
        ERC4626(asset)
        ERC20("Simple Interest Rate Claim", "cSIR")
    {
        simpleInterest = _simpleInterest;
    }

    // =============== deposit ===============

    // amount of shares that would be exchanged for the amount of assets provided
    // at the frequency of applying interest in the associated SimpleInterest contract
    // shares = assets - simpleInterest
    function convertToSharesAtFrequency(uint256 assets, uint256 interestFrequency)
        public
        view
        returns (uint256 shares)
    {
        if (interestFrequency == 0) return assets;

        uint256 interest = simpleInterest.interest(assets, interestFrequency);

        return assets - interest;
    }

    /**
     * @dev See {IERC4626-previewDeposit}.
     */
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        return convertToSharesAtFrequency(assets, currentInterestFrequency);
    }

    // =============== redeem ===============

    // amount of shares that would be exchanged for the amount of assets provided
    // at the frequency of applying interest in the associated SimpleInterest contract
    function convertToAssetsAtFrequency(uint256 shares, uint256 interestFrequency)
        public
        view
        returns (uint256 assets)
    {
        if (interestFrequency == 0) return shares;

        uint256 principal = simpleInterest.principalFromDiscounted(shares, (interestFrequency - 1));

        uint256 interest = simpleInterest.interest(principal, 1); // only ever give one period of interest

        return principal + interest;
    }

    /**
     * @dev See {IERC4626-previewDeposit}.
     */
    function setCurrentInterestFrequency(uint256 _interestFrequency) public {
        currentInterestFrequency = _interestFrequency;
    }
}

contract SimpleInterestVaultTest is Test {
    using Math for uint256;

    IERC20 private token;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");
    address private charlie = makeAddr("charlie");

    function setUp() public {
        uint256 tokenSupply = 10000;

        vm.startPrank(owner);
        token = new SimpleToken(tokenSupply);
        vm.stopPrank();

        uint256 userTokenAmount = 1000;

        assertEq(token.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(token, alice, userTokenAmount);
        transferAndAssert(token, bob, userTokenAmount);
        transferAndAssert(token, charlie, userTokenAmount);
    }

    function test__MultiVaultTest_Convert_Shares_Annual() public {
        uint256 apy = 5; // APY in percentage, e.g. 5%
        uint256 oneYear = 1; // 1 is a year

        // set up vault
        SimpleInterest simpleInterest = new SimpleInterest(apy, oneYear);
        SimpleInterestVault vault = new SimpleInterestVault(token, simpleInterest);

        uint256 depositAmount = 500;
        uint256 interestOneYear = simpleInterest.interest(depositAmount, 1); // equivalent of depositAmount.mulDiv(apy, 100);

        // 1 : 1 assets to shares to start
        uint256 zeroInterest = 0;
        assertVaultSharesCalculation(vault, depositAmount, 0, zeroInterest, "frequency Zero");
        depositAndAssert(vault, alice, depositAmount, zeroInterest, "frequency Zero");

        // 1 / APY shares for each asset at year 1
        assertVaultSharesCalculation(vault, depositAmount, interestOneYear, 1, "frequency One");
        vault.setCurrentInterestFrequency(1);
        depositAndAssert(vault, bob, depositAmount, interestOneYear, "frequency One");

        // 1 / (2 * APY) shares for each asset at year 2
        assertVaultSharesCalculation(vault, depositAmount, interestOneYear * 2, 2, "frequency Two");
        vault.setCurrentInterestFrequency(2);
        depositAndAssert(vault, charlie, depositAmount, interestOneYear * 2, "frequency Two");

        // ============== redeem ==============
        console2.log("================ start redeem ==============");

        uint256 expectedRedeem = (depositAmount + interestOneYear); // everyone should get 1 years worth of interest

        assertEq(expectedRedeem, vault.convertToAssetsAtFrequency(vault.balanceOf(alice), 1), "redeem at year 1");
        assertEq(expectedRedeem, vault.convertToAssetsAtFrequency(vault.balanceOf(bob), 2), "redeem at year 2");
        assertEq(expectedRedeem, vault.convertToAssetsAtFrequency(vault.balanceOf(charlie), 3), "redeem at year 3");
    }

    function assertVaultSharesCalculation(
        SimpleInterestVault _vault,
        uint256 depositAmount,
        uint256 expectedInterest,
        uint256 interestFrequency,
        string memory msgSuffix
    ) public {
        uint256 expectedShares = (depositAmount - expectedInterest);
        uint256 previousInterestFrequency = _vault.currentInterestFrequency();

        assertEq(
            expectedShares,
            _vault.convertToSharesAtFrequency(depositAmount, interestFrequency),
            string.concat("wrong convertToSharesAtFrequency ", msgSuffix)
        );

        _vault.setCurrentInterestFrequency(interestFrequency);
        assertEq(
            expectedShares, _vault.previewDeposit(depositAmount), string.concat("wrong previewDeposit ", msgSuffix)
        );
        assertEq(
            expectedShares, _vault.convertToShares(depositAmount), string.concat("wrong convertToShares ", msgSuffix)
        );

        _vault.setCurrentInterestFrequency(previousInterestFrequency);
    }

    function depositAndAssert(
        ERC4626 _vault,
        address toAddress,
        uint256 depositAmount,
        uint256 expectedInterest,
        string memory msgSuffix
    ) public {
        uint256 expectedShares = (depositAmount - expectedInterest);

        vm.startPrank(toAddress);

        uint256 beforeBalance = _vault.balanceOf(toAddress);

        IERC20 vaultAsset = (IERC20)(_vault.asset());
        vaultAsset.approve(address(_vault), depositAmount);

        _vault.deposit(depositAmount, toAddress);

        vm.stopPrank();

        assertEq(
            beforeBalance + expectedShares,
            _vault.balanceOf(toAddress),
            string.concat("vault balance wrong ", msgSuffix)
        );
    }

    function transferAndAssert(IERC20 _token, address toAddress, uint256 amount) public {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(owner);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
