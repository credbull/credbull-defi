//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract SimpleTokenVesting is ERC4626 {

    error SharesInVestingPeriod();

    VestingWallet public vestingWallet;
    IERC20 private immutable _asset;

    constructor(IERC20 asset, string memory name, string memory symbol, uint64 startTimestamp, uint64 durationSeconds)
    ERC4626(asset)
    ERC20(name, symbol)
    {
        _asset = asset;
        vestingWallet = new VestingWallet(address(this), startTimestamp, durationSeconds);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(vestingWallet));
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        SafeERC20.safeTransferFrom(_asset, caller, address(vestingWallet), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal virtual override {
        if (assets > vestingWallet.releasable(address(_asset))) {
            revert SharesInVestingPeriod();
        }

        vestingWallet.release(address(_asset));

        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }
}
