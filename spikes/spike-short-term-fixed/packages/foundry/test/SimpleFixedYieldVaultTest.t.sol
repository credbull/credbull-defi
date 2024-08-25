// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { console2 as console } from "forge-std/console2.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { OwnableToken } from "./OwnableToken.t.sol";
import { APY, SimpleFixedYieldVault, Term } from "../contracts/SimpleFixedYieldVault.sol";

contract SimpleFixedYieldVaultTest is Test {
    address private immutable OWNER = makeAddr("OWNER");
    address private immutable ALICE = makeAddr("ALICE");
    uint256 private constant INITIAL_SUPPLY = 100_000;
    ERC20 private underlyingAsset;
    SimpleFixedYieldVault private vault;

    function setUp() public {
        vm.startPrank(OWNER);
        underlyingAsset = new OwnableToken("Fake USDC", "USDC", 6, INITIAL_SUPPLY * 10 ** 6);
        vm.stopPrank();

        vault = new SimpleFixedYieldVault(APY.SIX_PERCENT, Term.THIRTY_DAYS, underlyingAsset);
    }

    function scaleForAsset(uint256 value) private view returns (uint256) {
        return value * 10 ** underlyingAsset.decimals();
    }

    function unscaleForAsset(uint256 value) private view returns (uint256) {
        return value / 10 ** underlyingAsset.decimals();
    }

    function test_SimpleFixedYieldVault_ExpectedSharesReturned() public {
        uint256 depositAmount = scaleForAsset(1_000);
        uint256 maxAmount = depositAmount * 10;

        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        vm.stopPrank();
        assertEq(1004931506, shares, "Incorrect amount of shares returned.");
    }

    function test_SimpleFixedYieldVault_ExpectedAssetsRedeemed() public {
        uint256 depositAmount = scaleForAsset(1_000);
        uint256 maxAmount = depositAmount * 10;

        vm.startPrank(OWNER);
        underlyingAsset.transfer(ALICE, maxAmount);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 shares = vault.deposit(depositAmount, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        vm.stopPrank();

        vm.startPrank(ALICE);
        underlyingAsset.approve(address(vault), maxAmount);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        uint256 assets = vault.redeem(shares, ALICE, ALICE);
        vm.warp(vm.getBlockTimestamp() + 5 seconds);
        vm.stopPrank();

        assertEq(1004931506, assets, "Incorrect amount of assets returned.");
    }
}
