// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedYieldVault } from "../FixedYieldVault.sol";

import { console2 } from "forge-std/Test.sol";

contract CredbullFixedYieldVaultWithUpside is FixedYieldVault {
    using Math for uint256;

    IERC20 public token;
    uint256 public twap = 1;
    uint256 public collateralPercentage;

    constructor(VaultParams memory params, IERC20 _token, uint256 _collateralPercentage) FixedYieldVault(params) {
        collateralPercentage = _collateralPercentage;
        token = _token;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 collateral = assets.mulDiv(collateralPercentage, 100) / twap;
        SafeERC20.safeTransferFrom(token, _msgSender(), address(this), collateral);

        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override returns (uint256) {
        uint256 collateral = shares.mulDiv(collateralPercentage, 100) / twap;
        SafeERC20.safeTransferFrom(token, _msgSender(), address(this), collateral);

        return super.mint(shares, receiver);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        uint256 collateral = calculateTokenRedemption(shares);
        SafeERC20.safeTransfer(token, receiver, collateral);

        return super.redeem(shares, receiver, owner);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        uint256 collateral = calculateTokenRedemption(previewWithdraw(assets));
        SafeERC20.safeTransfer(token, receiver, collateral);

        return super.withdraw(assets, receiver, owner);
    }

    function calculateTokenRedemption(uint256 shares) public view returns (uint256) {
        uint256 vaultPercent = shares.mulDiv(100, totalSupply());
        uint256 tokenBalance = token.balanceOf(address(this));
        return tokenBalance.mulDiv(vaultPercent, 100);
    }

    function setTWAP(uint256 _twap) public onlyRole(OPERATOR_ROLE) {
        twap = _twap;
    }
}
