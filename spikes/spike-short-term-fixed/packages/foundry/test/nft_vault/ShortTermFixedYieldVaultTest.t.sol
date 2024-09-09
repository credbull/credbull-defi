// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BaseTest.t.sol";
import { UserGenerator } from "./UserGenerator.sol";

contract ShortTermFixedYieldVaultTest is BaseTest, UserGenerator {
  uint256 public vaultOpenTime;
  uint256 public constant TOLERANCE = 1;

  function setUp() public {
    _deployContracts();

    vaultOpenTime = block.timestamp + 100;

    openVault(vaultOpenTime);
  }

  function depositInVault(uint256 amount, address user) public returns (uint256) {
    vm.startPrank(user);
    usdc.approve(address(vault), amount);
    uint256 tokenId = vault.deposit(amount);
    vm.stopPrank();

    return tokenId;
  }

  function withdrawFromVault(uint256 withdrawAmount, uint256 tokenId, address user) public {
    uint256 prevBalance = usdc.balanceOf(user);
    vm.prank(user);
    vault.withdraw(tokenId, withdrawAmount);
    assertEq(prevBalance + withdrawAmount, usdc.balanceOf(user));
  }

  function depositProcess(uint256 depositAmount, address user) public returns (uint256, uint256) {
    uint256 tokenId = depositInVault(depositAmount, user);

    assertEq(tokenId, 1);

    assertEq(vault.getWithdrawalAmount(tokenId), depositAmount);

    uint256 secondsElapsed = 86399;
    vm.warp(vaultOpenTime + secondsElapsed);

    tokenId = depositInVault(depositAmount, user);
    assertEq(tokenId, 1);

    assertEq(vault.getWithdrawalAmount(tokenId), depositAmount * 2);

    return (depositAmount * 2, tokenId);
  }

  /// @dev Check accumulatedAmount, withdrawAmount after 14 time periods elapsed
  function test_vaultProcessSenario1() public {
    uint256 depositAmount = 1000 * 10 ** usdc.decimals();
    address alice = generateUser(usdc);
    vm.warp(vaultOpenTime);

    (uint256 principal, uint256 tokenId) = depositProcess(depositAmount, alice);

    uint256 secondsElapsed = 14 days;
    vm.warp(vaultOpenTime + secondsElapsed);

    assertEq(vault.getCurrentTimePeriodsElapsed(), 14);
    assertEq(vault.getWithdrawalAmount(tokenId), principal);

    uint256 simulateAmount = simulateAmountWithFixedInterest(principal, 13);

    assertEq(vault.calculateAccumulatedAmount(tokenId), simulateAmount);
  }

  /// @dev Check accumulatedAmount, withdrawAmount after 30 time periods elapsed
  function test_vaultProcessSenario2() public {
    uint256 depositAmount = 1000 * 10 ** usdc.decimals();
    address alice = generateUser(usdc);
    vm.warp(vaultOpenTime);

    (uint256 principal, uint256 tokenId) = depositProcess(depositAmount, alice);

    uint256 secondsElapsed = 30 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getWithdrawalAmount(tokenId), principal);

    uint256 simulateAmount = simulateAmountWithFixedInterest(principal, 29);

    assertEq(vault.calculateAccumulatedAmount(tokenId), simulateAmount);
  }

  /**
   * @dev Check accumulatedAmount, withdrawAmount after 31 time periods elapsed
   * First term is passed
   */
  function test_vaultProcessSenario3() public {
    uint256 depositAmount = 1000 * 10 ** usdc.decimals();
    address alice = generateUser(usdc);
    vm.warp(vaultOpenTime);

    (uint256 principal, uint256 tokenId) = depositProcess(depositAmount, alice);

    uint256 secondsElapsed = 31 days;
    vm.warp(vaultOpenTime + secondsElapsed);

    uint256 simulateAmount = simulateCompoundingAmount(principal, 1);

    assertEq(vault.getWithdrawalAmount(tokenId), simulateAmount);
    assertEq(vault.calculateAccumulatedAmount(tokenId), simulateAmount);
  }

  /**
   * @dev Withdraw partial amount after 72 time periods elapsed
   * 2 terms are passed
   * Another 3 terms are passed (171 time periods elapsed)
   */
  function test_vaultProcessSenario4() public {
    uint256 depositAmount = 1000 * 10 ** usdc.decimals();
    address alice = generateUser(usdc);
    vm.warp(vaultOpenTime);

    (uint256 principal, uint256 tokenId) = depositProcess(depositAmount, alice);

    uint256 secondsElapsed = 72 days;
    vm.warp(vaultOpenTime + secondsElapsed);

    uint256 simulateAmount = simulateCompoundingAmount(principal, 2);
    simulateAmount = simulateAmountWithFixedInterest(simulateAmount, 11);

    assertApproxEqAbs(vault.calculateAccumulatedAmount(tokenId), simulateAmount, TOLERANCE);

    uint256 prevWithdrawalAmount = vault.getWithdrawalAmount(tokenId);

    uint256 withdrawAmount = 1000 * 10 ** 6;

    withdrawFromVault(withdrawAmount, tokenId, alice);

    assertEq(prevWithdrawalAmount - withdrawAmount, vault.getWithdrawalAmount(tokenId));

    principal = vault.getWithdrawalAmount(tokenId);

    // change the time
    secondsElapsed = 171 days;
    vm.warp(vaultOpenTime + secondsElapsed);

    simulateAmount = simulateCompoundingAmount(principal, 3);
    assertApproxEqAbs(vault.getWithdrawalAmount(tokenId), simulateAmount, TOLERANCE);

    simulateAmount = simulateAmountWithFixedInterest(simulateAmount, 20);

    assertApproxEqAbs(vault.calculateAccumulatedAmount(tokenId), simulateAmount, TOLERANCE);

    (uint256 periodsUntilTermEnd, uint256 currentYield, uint256 accumulatedAmount) = vault.getDepositInfo(tokenId);

    assertEq(accumulatedAmount, simulateAmount);
    assertEq(periodsUntilTermEnd, 10);
    assertApproxEqAbs(currentYield, simulateAmount - principal, TOLERANCE);
  }

  /**
   * @dev Withdraw max amount after 139 time periods elapsed
   * 4 terms are passed
   */
  function test_vaultProcessSenario5() public {
    uint256 depositAmount = 1000 * 10 ** usdc.decimals();
    address alice = generateUser(usdc);
    vm.warp(vaultOpenTime);
    (uint256 principal, uint256 tokenId) = depositProcess(depositAmount, alice);

    uint256 secondsElapsed = 139 days;
    vm.warp(vaultOpenTime + secondsElapsed);

    uint256 withdrawalAmount = simulateCompoundingAmount(principal, 4);
    assertApproxEqAbs(vault.getWithdrawalAmount(tokenId), withdrawalAmount, TOLERANCE);

    uint256 simulateAmount = simulateAmountWithFixedInterest(withdrawalAmount, 18);

    assertApproxEqAbs(vault.calculateAccumulatedAmount(tokenId), simulateAmount, TOLERANCE);

    vaultAssetsUpdate();

    assertTrue(vault.ownerOf(tokenId) == alice);

    uint256 prevBalance = usdc.balanceOf(alice);
    vm.prank(alice);
    vault.withdrawMax(tokenId);
    assertApproxEqAbs(prevBalance + withdrawalAmount, usdc.balanceOf(alice), TOLERANCE);

    vm.expectRevert();
    assertTrue(vault.ownerOf(tokenId) != alice);
  }
}
