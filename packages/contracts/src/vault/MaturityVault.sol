//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Vault } from "./Vault.sol";

/**
 * @title A Credbull Vault with Maturity properties.
 * @author @pasviegas
 * @notice Once matured, such a vault will not accept further deposits.
 */
abstract contract MaturityVault is Vault {
    /// @notice The set of parameters for creating a [MaturityVault].abi
    /// @dev Though unnecessary, we maintain the implementation pattern of a 'Params' per Vault.
    struct MaturityVaultParams {
        VaultParams vault;
    }

    /// @notice Reverts on withdraw if vault is not matured.
    error CredbullVault__NotMatured();

    /// @notice Reverts on mature if there is not enough balance.
    error CredbullVault__NotEnoughBalanceToMature();

    /// @notice Event emitted when the vault matures.
    event VaultMatured(uint256 indexed totalAssetDeposited);

    /// @notice Determine if the vault is matured or not.
    bool public isMatured;

    /// @notice Determine if Maturity Checking is enabled or disabled.
    bool public checkMaturity;

    constructor(MaturityVaultParams memory params) Vault(params.vault) {
        checkMaturity = true;
    }

    /**
     * @notice - Method to mature the vault by by depositing back the asset from the custodian wallet with addition
     *  yield earned.
     * @dev - _totalAssetDeposited to be updated to calculate the right amount of asset with yield in proportion to
     *  the shares.
     */
    function _mature() internal {
        uint256 currentBalance = IERC20(asset()).balanceOf(address(this));

        if (expectedAssetsOnMaturity() > currentBalance) {
            revert CredbullVault__NotEnoughBalanceToMature();
        }

        totalAssetDeposited = currentBalance;
        isMatured = true;

        emit VaultMatured(totalAssetDeposited);
    }

    /// @notice - Returns expected assets on maturity
    function expectedAssetsOnMaturity() public view virtual returns (uint256) {
        return totalAssetDeposited;
    }

    /// @dev - To be access controlled on inherited contract
    function mature() public virtual {
        _mature();
    }

    /**
     * @notice - Function to check for maturity status.
     * @dev - Used in withdraw modifier to check for maturity status
     */
    function _checkVaultMaturity() internal view {
        if (checkMaturity && !isMatured) {
            revert CredbullVault__NotMatured();
        }
    }

    /**
     * @notice Enables/disables the Maturity Check according to the [status] value.
     * @dev 'Toggling' means flipping the existing state. This is simply a mutator.
     * @param status Boolean value to toggle
     */
    function _toggleMaturityCheck(bool status) internal {
        checkMaturity = status;
    }
}
