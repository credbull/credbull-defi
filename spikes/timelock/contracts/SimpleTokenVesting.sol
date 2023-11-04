//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract SimpleTokenVesting is VestingWallet {
  constructor(address beneficiary, uint64 startTimestamp, uint64 durationSeconds)
  VestingWallet(beneficiary, startTimestamp, durationSeconds)
  {}
}
