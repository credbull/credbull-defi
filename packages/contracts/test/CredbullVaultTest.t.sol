// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CredbullVault} from "../src/CredbullVault.sol";
import {DeployCredbullVault} from "../script/DeployCredbullVault.s.sol";

interface IERC20 {
    function symbol() external view returns (string memory);
}

contract CredbullVaultTest is Test {
    CredbullVault public credbullVault;

    // Vaults exchange Assets for Shares in the Vault
    string public assetSymbol; 
    string public shareSymbol;

    function setUp() public {
        DeployCredbullVault deployCredbullVault = new DeployCredbullVault();
        credbullVault = deployCredbullVault.run();

        assetSymbol = "USDT";
        shareSymbol = deployCredbullVault.VAULT_SHARE_SYMBOL();
    }

    function testDeploymentReturnsToken() public {
        DeployCredbullVault deployCredbullVault = new DeployCredbullVault();

        assertTrue(address(deployCredbullVault.run()) != address(0x00));
    }

    function testOwnerIsMsgSender() public {
        console.log("1. Msg sender", msg.sender);
        console.log("2. Token Owner", credbullVault.owner());

        assertEq(credbullVault.owner(), msg.sender);
    }

    function testShareSymbolIsSetCorrectly() public {
        assertEq(credbullVault.symbol(), shareSymbol);        
    }

    function testAssetIsTetherToken() public {
        IERC20 asset = IERC20(credbullVault.asset());        
        assertEq(asset.symbol(), "USDT");
    }

}