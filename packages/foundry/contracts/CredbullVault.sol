// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { console2 } from "forge-std/console2.sol";

// Vaults exchange Assets for Shares in the Vault
// see: https://eips.ethereum.org/EIPS/eip-4626
contract CredbullVault is ERC4626, Ownable {
    //Error to revert on withdraw if Rebase is not completed
    error CredbullVault__RebaseNotCompleted();

    //Address of the custodian to recieve the assets on deposit and mint
    address public custodian;

    /**
     * @dev
     * The assets deposited to the vault will be sent to custodian address so this is
     * separate variable to track the total assets that's been deposited to this vault.
     */
    uint256 private _totalAssetDeposited;

    //A variable to track status of rebase
    bool private isRebaseCompleted;

    /**
     * @notice - Modifier to check for rebase status.
     * @dev - Used on internal withdraw method to check for rebase status
     */
    modifier onlyAfterRebase() {
        if (!isRebaseCompleted) {
            revert CredbullVault__RebaseNotCompleted();
        }

        _;
    }

    /**
     * @param _owner - The owner of this contract
     * @param _asset - The address of the asset to be deposited to this vault
     * @param _shareName - The name for the share token of the vault
     * @param _shareSymbol - The symbol for the share tokenn of the vault
     * @param _custodian - The custodian wallet address to transfer asset.
     */
    constructor(address _owner, IERC20 _asset, string memory _shareName, string memory _shareSymbol, address _custodian)
        ERC4626(_asset)
        ERC20(_shareName, _shareSymbol)
        Ownable(_owner)
    {
        custodian = _custodian;
    }

    /**
     * @dev - The internal deposit function of ERC4626 overridden to transfer the asset to custodian wallet
     * and update the _totalAssetDeposited on deposit/mint
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, custodian, assets);
        _totalAssetDeposited += assets;

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev - The internal withdraw function of ERC4626 overridden to update the _totalAssetDeposited on withdraw/redeem
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        override
        onlyAfterRebase
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
        _totalAssetDeposited -= assets;

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @notice - Returns the total assets deposited into the vault
     * @dev - The function is overriden to return the _totalAssetDeposited value to calculate shares.
     */
    function totalAssets() public view override returns (uint256) {
        return _totalAssetDeposited;
    }

    /**
     * @notice - Rebase method to deposit back the assets that was sent to custodian wallet with addition yeild earned.
     * @dev - _totalAssetDeposited to be updated to calculate the right amount of asset with yeild in proportion to the shares received.
     *
     * @custom:audit - The logic used in the function is based on the assumption that the 'amount' will always be currect with additional 10% yield.
     * Any valut less than the '_totalAssetDeposited' will result in unexpected behaviour, where users might get less asset than they deposited and
     * also possiblility of early withdraw since rebaseCompleted is set to true.
     *
     * TODO: Finalize on the logic on updating the _totalAssetDeposited value
     *
     * @param amount - The total number of asset to be deposited back.
     */
    function rebase(uint256 amount) external onlyOwner {
        isRebaseCompleted = true;
        SafeERC20.safeTransferFrom(IERC20(asset()), msg.sender, address(this), amount);
        _totalAssetDeposited = IERC20(asset()).balanceOf(address(this));
    }
}
