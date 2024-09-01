// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ShortTermFixedYieldVault } from "../../contracts/nft_vault/ShortTermFixedYieldVault.sol";
import { MockUSDC } from "../../contracts/nft_vault/MockUSDC.sol";

abstract contract BaseTest is Test {
  ShortTermFixedYieldVault public vault;
  MockUSDC public usdc;

  address public vaultOwner = address(0x323323);

  function _deployContracts() internal virtual {
    usdc = new MockUSDC("USDC", "usdc");

    vm.prank(vaultOwner);
    vault = new ShortTermFixedYieldVault(address(usdc));
  }
}
