// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MockToken is IERC20 {
    function totalSupply() external view override returns (uint256) {}

    function balanceOf(address account) external view override returns (uint256) {}

    function transfer(address to, uint256 amount) external override returns (bool) {}

    function allowance(address owner, address spender) external view override returns (uint256) {}

    function approve(address spender, uint256 amount) external override returns (bool) {}

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {}
}

// Vaults exchange Assets for Shares in the Vault
// see: https://eips.ethereum.org/EIPS/eip-4626
contract CredbullMultiSigVault is ERC4626, Ownable {
    constructor(IERC20 _asset, string memory _shareName, string memory _shareSymbol)
        ERC4626(_asset)
        ERC20(_shareName, _shareSymbol)
    {}
}

// Test Cases to add:
// -- Test out the withdraw flow - single party
// -- Test out the withdraw flow - multi party
// -- Depositing a Token that isn't the Asset should fail.  E.g. Asset is Tether, trying to deposit USDC should fail.
contract CredbullMultiSigVaultTest is Test {
    IERC20 asset;
    CredbullMultiSigVault credbullVault;

    function setUp() public {
        vm.startBroadcast();

        asset = new MockToken();
        credbullVault = new CredbullMultiSigVault(
            asset,
            "Mock Token",
            "MT"
        );

        vm.stopBroadcast();
    }

    function testOwnerIsMsgSender() public {
        console.log("Token Owner", credbullVault.owner());

        assertEq(credbullVault.owner(), msg.sender);
    }
}
