//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract SimpleShareMultiplierVault is ERC4626 {

    mapping(address => uint8) public _multipliers;

    constructor(IERC20 asset, string memory name, string memory symbol)
    ERC4626(asset)
    ERC20(name, symbol)
    {}

    function addMultiplier(address owner, uint8 _multiplier) public {
        _multipliers[owner] = _multiplier;
    }

    function multiplier(address owner) public view returns (uint8) {
        return _multipliers[owner];
    }

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint8 _multiplier = 1;
        if (_multipliers[receiver] > 0) {
            _multiplier = _multipliers[receiver];
        }

        uint256 shares = previewDeposit(assets) * _multiplier;
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint8 _multiplier = 1;
        if (_multipliers[receiver] > 0) {
            _multiplier = _multipliers[receiver];
        }

        uint256 assets = previewMint(shares) / _multiplier;
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }
}
