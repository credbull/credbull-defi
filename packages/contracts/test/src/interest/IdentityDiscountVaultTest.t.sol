// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IDiscountVault } from "@credbull/interest/IDiscountVault.sol";
import { IdentityDiscountVault } from "@credbull/interest/IdentityDiscountVault.sol";
import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";

import { DiscountVaultTestBase } from "./DiscountVaultTestBase.t.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SimpleIERC1155 is ERC1155, IERC1155MintAndBurnable {
    constructor() ERC1155("") { }

    function mint(address to, uint256 id, uint256 value, bytes memory data) public override {
        _mint(to, id, value, data);
    }

    function burn(address from, uint256 id, uint256 value) public override {
        _burn(from, id, value);
    }
}

contract IdentityDiscountVaultTest is DiscountVaultTestBase {
    using Math for uint256;

    IERC20Metadata private asset;
    IERC1155MintAndBurnable private depositLedger;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        depositLedger = new SimpleIERC1155();
    }

    // Scenario: Calculating returns for a standard investment
    function test__IdentityDiscountVault__SharesAndAssetsEqual() public {
        uint256 apy = 6; // APY in percentage
        uint256 principal = 50_000 * SCALE;

        IDiscountVault vault = new IdentityDiscountVault(asset, depositLedger, apy);

        uint256 depositPeriod = 15;
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // warp to deposit period

        // ------------------- deposit -------------------
        vm.startPrank(alice);
        asset.approve(address(vault), principal); // grant the vault allowance
        uint256 shares = vault.deposit(principal, alice); // now deposit
        vm.stopPrank();

        assertEq(principal, shares, "shares not calculated correctly");
        assertEq(principal, depositLedger.balanceOf(alice, depositPeriod), "ledger not updated on deposit");
        assertEq(principal, vault.balanceOf(alice), "vault shares not updated on deposit");

        // ------------------- redeem -------------------
        vm.startPrank(alice);
        uint256 assets = vault.redeem(shares, alice, alice);

        assertEq(principal, assets, "assets not calculated correctly");
        assertEq(0, depositLedger.balanceOf(alice, depositPeriod), "ledger not updated on redeem");
        assertEq(0, vault.balanceOf(alice), "vault shares not updated on redeem");

        testVaultAtPeriods(principal, vault, depositPeriod + 1);
    }
}
