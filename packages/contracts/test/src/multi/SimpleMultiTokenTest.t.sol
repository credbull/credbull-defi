// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SimpleMultiToken } from "./SimpleMultiToken.s.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { SimpleMultiToken } from "./SimpleMultiToken.s.sol";

contract SimpleUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract SimpleMultiTokenTest is Test {
    SimpleMultiToken private multiToken;
    SimpleUSDC private usdc;

    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    function setUp() public {
        uint256 tenor = 30; // 30 days

        vm.startPrank(owner);

        usdc = new SimpleUSDC();
        usdc.mint(alice, 1000 * 10 ** usdc.decimals());
        usdc.mint(bob, 1000 * 10 ** usdc.decimals());

        multiToken = new SimpleMultiToken(owner, usdc, tenor);
        vm.stopPrank();
    }

    function test__SimpleMultiTokenTest__Deposit() public {
        uint256 depositAmount = 1000;

        // Transfer underlying assets to Alice
        vm.startPrank(owner);
        multiToken.mint(alice, multiToken.PERIODS_0(), depositAmount, "");
        multiToken.mint(bob, multiToken.PERIODS_1(), depositAmount, "");
        vm.stopPrank();

        assertEq(depositAmount, multiToken.balanceOf(alice, multiToken.PERIODS_0()));
        assertEq(0, multiToken.balanceOf(bob, multiToken.PERIODS_0()));

        assertEq(0, multiToken.balanceOf(alice, multiToken.PERIODS_1()));
        assertEq(depositAmount, multiToken.balanceOf(bob, multiToken.PERIODS_1()));
    }

    function test__SimpleMultiTokenTest__Vault_Deposit() public {
        uint256 depositAmount = 100 * 10 ** usdc.decimals();
        uint256 expectedShares = multiToken.convertToShares(depositAmount);

        // Alice approves the multiToken contract to spend her USDC
        vm.startPrank(alice);
        usdc.approve(address(multiToken), depositAmount);

        // Alice deposits USDC into the vault
        uint256 shares = multiToken.deposit(depositAmount, alice);
        vm.stopPrank();

        assertEq(shares, expectedShares, "Incorrect number of shares minted");
        assertEq(multiToken.balanceOf(alice), shares, "Alice's share balance is incorrect");
        assertEq(usdc.balanceOf(address(multiToken)), depositAmount, "Vault's USDC balance is incorrect");
    }

    function test__SimpleMultiTokenTest__Vault_RedeemFull() public {
        uint256 aliceUsdcBalanceBefore = usdc.balanceOf(alice);
        uint256 depositAmount = 100 * 10 ** usdc.decimals();

        // Alice approves the multiToken contract to spend her USDC and deposits the full amount
        vm.startPrank(alice);
        usdc.approve(address(multiToken), depositAmount);
        multiToken.deposit(depositAmount, alice);

        // Alice redeems all her shares
        uint256 shares = multiToken.balanceOf(alice);
        uint256 assets = multiToken.redeem(shares, alice, alice);
        vm.stopPrank();

        assertEq(assets, depositAmount, "Incorrect number of assets returned after full redeem");
        assertEq(multiToken.balanceOf(alice), 0, "Alice should have no shares left");
        assertEq(
            usdc.balanceOf(alice),
            aliceUsdcBalanceBefore,
            "Alice's USDC balance should be restored to the initial amount"
        );
        assertEq(usdc.balanceOf(address(multiToken)), 0, "Vault should have no USDC left");
    }
}
