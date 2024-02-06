// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CredbullUpsideVault is ERC4626 {
    ERC4626 public baseVault;
    ERC4626 public upsideVault;

    uint256 public twap = 1;

    constructor(
        address _baseVault,
        address _upsideVault,
        IERC20 _asset,
        string memory _shareName,
        string memory _shareSymbol
    ) ERC4626(_asset) ERC20(_shareName, _shareSymbol) {
        baseVault = ERC4626(_baseVault);
        upsideVault = ERC4626(_upsideVault);
    }

    function deposit(uint256 assets, address receiver, bool upside) public virtual returns (uint256) {
        uint256 shares = 0;
        if (upside) {
            shares = super.deposit(assets * twap, receiver);
            upsideVault.deposit(assets, receiver);
        } else {
            baseVault.deposit(assets, receiver);
        }

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner, bool upside) public virtual returns (uint256) {
        uint256 assets = 0;
        if (upside) {
            assets = super.redeem(shares, receiver, owner);
            upsideVault.redeem(shares, receiver, owner);
        } else {
            baseVault.redeem(shares, receiver, owner);
        }

        return assets;
    }
}