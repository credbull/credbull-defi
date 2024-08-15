// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterestTest.t.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

// import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At interestFrequency 1, 1 asset gives 1 / APY shares
// - At interestFrequency 2, 1 asset gives 1 / (2 * APY) shares,
// - and so on...
//
// This is like having linear deflation over time.
contract SimpleInterestVault is ERC4626 {
    SimpleInterest private simpleInterest;

    constructor(IERC20 asset, SimpleInterest _simpleInterest)
        ERC4626(asset)
        ERC20("Simple Interest Rate Claim", "cSIR")
    {
        simpleInterest = _simpleInterest;
    }

    // amount of shares that would be exchanged for the amount of assets provided
    // at the frequency of applying interest in the associated SimpleInterest contract
    function convertToSharesAtFrequency(uint256 assets, uint256 interestFrequency)
        public
        view
        returns (uint256 shares)
    {
        if (interestFrequency == 0) return assets;

        return assets / simpleInterest.interest(assets, interestFrequency);
    }
}

contract SimpleInterestVaultTest is Test {
    IERC20 private token;

    function setUp() public {
        token = new SimpleToken(10000);
    }

    function test__MultiVaultTest_Annual() public {
        uint256 apy = 3; // APY in percentage
        uint256 oneYear = 1; // 1 is a year

        SimpleInterest simpleInterest = new SimpleInterest(apy, oneYear);
        SimpleInterestVault vault = new SimpleInterestVault(token, simpleInterest);

        uint256 deposit = 100;
        assertEq(0, simpleInterest.interest(deposit, 0));
        assertEq(apy, simpleInterest.interest(deposit, 1)); // 1 year
        assertEq(apy * 2, simpleInterest.interest(deposit, 2)); // 2 years

        // 1 : 1 assets to shares to start
        assertEq(deposit, vault.convertToSharesAtFrequency(deposit, 0));

        // 1 / APY shares for each asset at year 1
        assertEq(deposit / apy, vault.convertToSharesAtFrequency(deposit, 1));

        // 1 / (2 * APY) shares for each asset at year 2
        assertEq(deposit / (apy * 2), vault.convertToSharesAtFrequency(deposit, 2));
    }
}
