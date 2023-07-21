// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CredbullVault} from "../src/CredbullVault.sol";
import {DeployCredbullVault} from "../script/DeployCredbullVault.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CredbullVaultTest is Test {
    CredbullVault public credbullVault;
    DeployCredbullVault deployCredbullVault;

    function setUp() public {
        deployCredbullVault = new DeployCredbullVault();
        credbullVault = deployCredbullVault.run();
    }

    function testDeploymentReturnsToken() public {
        assertTrue(address(deployCredbullVault.run()) != address(0x00));
    }

    function testOwnerIsMsgSender() public {
        console.log("Token Owner", credbullVault.owner());

        assertEq(credbullVault.owner(), msg.sender);
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

    // TODO!
    function testDepositTetherGetShare() public {
        address alice = makeAddr("alice");
        vm.deal(alice, 50 ether);
    }

    // TODO!
    function testDepositCredbullTokenGetNothing() public {
    }
}