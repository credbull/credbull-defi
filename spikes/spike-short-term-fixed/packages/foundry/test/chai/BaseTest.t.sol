// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { ShortTermFixedYieldVault } from "@credbull-spike/contracts/chai/ShortTermFixedYieldVault.sol";
import { MockUSDC } from "@credbull-spike/contracts/chai/MockUSDC.sol";

abstract contract BaseTest is Test {
  ShortTermFixedYieldVault public vault;
  MockUSDC public usdc;

  address public vaultOwner = address(0x323323);
  uint256 public constant FIXED_APY = 10;

  function _deployContracts() internal virtual {
    usdc = new MockUSDC("USDC", "usdc");

    vm.prank(vaultOwner);
    vault = new ShortTermFixedYieldVault(address(usdc));
  }

  function openVault(
    uint256 vaultOpenTime
  ) public {
    vm.prank(vaultOwner);
    vault.openVault(vaultOpenTime);
  }

  function vaultAssetsUpdate() public {
    usdc.mint(address(this), 100000 * 10 ** usdc.decimals());

    usdc.transfer(address(vault), 100000 * 10 ** usdc.decimals());
  }

  function simulateAmountWithFixedInterest(uint256 principal, uint256 noOfPeriods) public pure returns (uint256) {
    return principal + principal * FIXED_APY * noOfPeriods / 36500;
  }

  function simulateCompoundingAmount(uint256 principal, uint256 noOfTerms) public pure returns (uint256 simulateAmount) {
    uint256 i;
    simulateAmount = principal;
    for (i = 0; i < noOfTerms; i++) {
      simulateAmount = simulateAmount + simulateAmount * FIXED_APY * 30 / 36500;
    }

    return simulateAmount;
  }
}
