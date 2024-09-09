// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BaseTest.t.sol";
import { UserGenerator } from "./UserGenerator.sol";
import { ABDKMath64x64 } from "../../contracts/nft_vault/ABDKMath64x64.sol";

contract VaultViewFuncTest is BaseTest, UserGenerator {
  function setUp() public {
    _deployContracts();
  }

  function openVault(
    uint256 vaultOpenTime
  ) public {
    vm.prank(vaultOwner);
    vault.openVault(vaultOpenTime);
  }

  function test_RevertIf_VaultIsNotOpen() public {
    vm.prank(vaultOwner);
    vault.unpause();

    vm.expectRevert(abi.encodeWithSelector(ShortTermFixedYieldVault.VaultNotOpen.selector));
    vault.deposit(10000);
  }

  function test_openVault() public {
    uint256 vaultOpenTime = block.timestamp - 1;

    vm.prank(vaultOwner);
    vm.expectRevert(abi.encodeWithSelector(ShortTermFixedYieldVault.InvalidOpenTime.selector));
    vault.openVault(vaultOpenTime);

    vaultOpenTime = block.timestamp + 1000;
    vm.prank(vaultOwner);
    vault.openVault(vaultOpenTime);

    assertEq(vaultOpenTime, vault.vaultOpenTime());
  }

  function testFuzz_getCurrentTimePeriodsElapsed(
    uint64 secondsElapsed
  ) public {
    uint256 vaultOpenTime = block.timestamp + 1000;
    openVault(vaultOpenTime);

    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getCurrentTimePeriodsElapsed(), secondsElapsed / 86400);
  }

  function testFuzz_getDepositLockTimePeriods(uint64 secondsElapsed, uint64 timePeriodsFromOpen) public {
    vm.assume(timePeriodsFromOpen <= type(uint64).max / 86400 && secondsElapsed >= timePeriodsFromOpen * 86400);

    uint256 vaultOpenTime = block.timestamp + 1000;

    openVault(vaultOpenTime);

    vm.warp(vaultOpenTime + secondsElapsed);

    uint256 simul_result =
      (secondsElapsed / 86400 - timePeriodsFromOpen) <= 1 ? 0 : (secondsElapsed / 86400 - timePeriodsFromOpen - 1);

    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), simul_result);
  }

  function test_getDepositLockTimePeriods() public {
    uint256 vaultOpenTime = block.timestamp + 1000;
    openVault(vaultOpenTime);

    uint256 secondsElapsed = 45000;

    // timePeriods when deposit
    uint256 timePeriodsFromOpen = 0;

    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 0);

    secondsElapsed = 1 days + 4300;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 0);

    secondsElapsed = 2 days + 1;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 1);

    secondsElapsed = 31 days + 2100;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 30);

    secondsElapsed = 61 days + 10;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 60);

    timePeriodsFromOpen = 24;

    secondsElapsed = 49 days + 3420;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 24);

    secondsElapsed = 55 days + 12;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 30);

    secondsElapsed = 85 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 60);
  }

  function test_getTimePeriodsElapsedInCurrentTerm() public {
    uint256 vaultOpenTime = block.timestamp + 1000;
    openVault(vaultOpenTime);

    uint256 secondsElapsed = 45000;
    uint256 timePeriodsFromOpen = 0;
    vm.warp(vaultOpenTime + secondsElapsed);

    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 0);

    secondsElapsed = 1 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 0);

    secondsElapsed = 2 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 1);

    secondsElapsed = 30 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 29);

    secondsElapsed = 31 days;
    vm.warp(vaultOpenTime + secondsElapsed);

    // 0 time periods in second term
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 0);
    assertEq(vault.getNoOfTermsElapsed(timePeriodsFromOpen), 1);

    secondsElapsed = 33 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 2);
    assertEq(vault.getNoOfTermsElapsed(timePeriodsFromOpen), 1);

    secondsElapsed = 67 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 6);
    assertEq(vault.getNoOfTermsElapsed(timePeriodsFromOpen), 2);

    secondsElapsed = 137 days + 3420;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 16);
    assertEq(vault.getNoOfTermsElapsed(timePeriodsFromOpen), 4);

    // ----------------------
    timePeriodsFromOpen = 27;

    secondsElapsed = timePeriodsFromOpen * 1 days + 1200;
    vm.warp(vaultOpenTime + secondsElapsed);

    assertEq(vault.getCurrentTimePeriodsElapsed(), 27);
    assertEq(vault.getDepositLockTimePeriods(timePeriodsFromOpen), 0);

    secondsElapsed = 29 days;
    vm.warp(vaultOpenTime + secondsElapsed);
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 1);
    assertEq(vault.getNoOfTermsElapsed(timePeriodsFromOpen), 0);
  }

  function test_getTimePeriodsInCurrentTermStart() public {
    uint256 vaultOpenTime = block.timestamp + 1000;
    openVault(vaultOpenTime);

    uint256 secondsElapsed = 42 days + 1200;
    uint256 timePeriodsFromOpen = 0;
    vm.warp(vaultOpenTime + secondsElapsed);

    uint256 newTimePeriodsFromOpen = vault.getTimePeriodsInCurrentTermStart(timePeriodsFromOpen);
    assertEq(newTimePeriodsFromOpen, 30);

    timePeriodsFromOpen = newTimePeriodsFromOpen;
    assertEq(vault.getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen), 11);
  }

  function test_ABDKMath64x64Test() public pure {
    uint256 x = 2000;
    int128 y = ABDKMath64x64.fromUInt(x);
    uint256 r;
    // return is uint64
    r = ABDKMath64x64.toUInt(y);
    assertEq(r, 2000);
    x = 4;
    y = ABDKMath64x64.fromUInt(x);
    r = ABDKMath64x64.toUInt(ABDKMath64x64.exp_2(y));
    assertEq(r, 16);
    uint256 num = 1000;
    y = ABDKMath64x64.fromUInt(num);
    y = ABDKMath64x64.log_2(y);
    r = ABDKMath64x64.toUInt(y);
    assertEq(r, 9);
  }
}
