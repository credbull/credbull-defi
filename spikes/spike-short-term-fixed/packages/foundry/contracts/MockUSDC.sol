//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract MockUSDC is ERC20Permit, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role");
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role");
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    uint256 initialBalance
  ) payable ERC20(name, symbol) ERC20Permit(name) {
    _mint(msg.sender, initialBalance);
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MINTER_ROLE, _msgSender());
  }

  function mint(address account, uint256 amount) external onlyMinter {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyMinter {
    _burn(account, amount);
  }

  function setMinterRole(address account) external onlyAdmin {
    _grantRole(MINTER_ROLE, account);
  }

  function removeMinterRole(address account) external onlyAdmin {
    _revokeRole(MINTER_ROLE, account);
  }
}
