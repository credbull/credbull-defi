// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Test, console } from "forge-std/Test.sol";
import { CredbullVault } from "../contracts/CredbullVault.sol";
import { DeployCredbullVault } from "../script/DeployCredbullVault.s.sol";

import {INetworkConfig } from "../script/utils/NetworkConfig.s.sol";
import {LocalNetworkConfig} from "../script/utils/LocalNetworkConfig.s.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Test Cases to add:
// -- Test out the withdraw flow - single party
// -- Test out the withdraw flow - multi party
// -- Depositing a Token that isn't the Asset should fail.  E.g. Asset is USDC, trying to deposit Tether should fail.
contract CredbullVaultTest is Test {
    DeployCredbullVault deployCredbullVault;
    CredbullVault public credbullVault;
    address contractOwnerAddr;

    function setUp() public {
        contractOwnerAddr = msg.sender;

        INetworkConfig networkConfig = new LocalNetworkConfig(contractOwnerAddr);
        deployCredbullVault = new DeployCredbullVault(networkConfig);
        credbullVault = deployCredbullVault.run(contractOwnerAddr);
    }

    function testDeploymentReturnsToken() public {
        assertTrue(address(deployCredbullVault.run()) != address(0));
    }

    function testOwnerIsMsgSender() public {
        console.log("Token Owner", credbullVault.owner());

        assertEq(credbullVault.owner(), contractOwnerAddr);
    }

    function testShareSymbolIsSetOnDeploy() public {
        assertEq(credbullVault.symbol(), deployCredbullVault.getVaultShareSymbol());
    }

    function testAssetIsSetOnDeployByAddress() public {
        assertEq(credbullVault.asset(), address(deployCredbullVault.getCredbullVaultAsset()));
    }

    function testAssetIsSetOnDeployByERC20MetaData() public {
        IERC20Metadata asset = IERC20Metadata(credbullVault.asset());
        IERC20Metadata deployedAsset = IERC20Metadata(address(deployCredbullVault.getCredbullVaultAsset()));

        assertEq(asset.symbol(), deployedAsset.symbol());
        assertEq(asset.name(), deployedAsset.name());
    }

    function testOwnerHasAssetTotalSupply() public {
        IERC20 asset = IERC20(credbullVault.asset());

        assertEq(asset.balanceOf(contractOwnerAddr), asset.totalSupply());
    }

    function testTotalAssetsIsZero() public {
        assertEq(0, credbullVault.totalAssets());
    }

    function testDepositAssetGetShares() public {
        // ---- Setup Part 1, give alice some Assets ----
        IERC20 asset = IERC20(credbullVault.asset());

        assertEq(asset.balanceOf(address(credbullVault)), 0, "Vault should start with no assets");
        assertEq(credbullVault.totalAssets(), 0, "Vault should start with no assets");

        assertEq(asset.balanceOf(contractOwnerAddr), asset.totalSupply());

        address alice = makeAddr("alice");
        uint256 transferAmount = 10;
        transfer(asset, alice, transferAmount);

        // ---- Setup Part 2 - Alice transfers assets for shares ----

        assertEq(credbullVault.balanceOf(alice), 0, "User should start with no Shares");

        // first, approve the deposit
        vm.prank(alice);
        asset.approve(address(credbullVault), transferAmount);

        // now we can deposit, alice is the caller and receiver
        vm.prank(alice);
        uint256 sharesAmount = credbullVault.deposit(transferAmount, alice);

        // ---- Assert - Vault gets the Assets, Alice gets Shares ----

        // Vault should have the assets
        assertEq(credbullVault.totalAssets(), transferAmount, "Vault should now have the assets");
        assertEq(asset.balanceOf(address(credbullVault)), transferAmount, "Vault should now have the assets");

        // Alice should have the shares
        assertEq(sharesAmount, transferAmount, "User should now have the Shares");
        assertEq(credbullVault.balanceOf(alice), transferAmount, "User should now have the Shares");
    }

    // ========== Utility functions ==========
    function transfer(IERC20 erc20token, address to, uint256 transferAmount) public {
        transfer(erc20token, contractOwnerAddr, to, transferAmount);
    }

    function transfer(IERC20 erc20token, address from, address to, uint256 transferAmount) public {
        uint256 toBalanceBeforeTransfer = erc20token.balanceOf(to);

        vm.prank(from);
        erc20token.transfer(to, transferAmount);

        uint256 toBalanceAfterTransfer = erc20token.balanceOf(to);

        assertEq(
            toBalanceBeforeTransfer + transferAmount, toBalanceAfterTransfer, "Should have transferred the full amount"
        );
    }
}
