//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IShortTermFixedYieldVault {
  event VaultOpened(uint256 openTime);
  event Deposited(address indexed user, uint256 amount, uint256 tokenId, uint256 time);
  event Withdrawn(address indexed user, uint256 amount, uint256 tokenId, uint256 time);

  function openVault(
    uint256 _vaultOpenTime
  ) external;

  function deposit(
    uint256 amount
  ) external returns (uint256 tokenId);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 tokenId);

  function withdraw(uint256 tokenId, uint256 amount) external;
  function withdrawMax(
    uint256 tokenId
  ) external;

  function getDepositInfo(
    uint256 tokenId
  ) external view returns (uint256 remainingLockPeriods, uint256 currentYield, uint256 withdrawalAmount);
  function canWithdraw(
    uint256 tokenId
  ) external view returns (bool);
}
