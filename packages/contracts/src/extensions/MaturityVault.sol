//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { CredbullBaseVault } from "../base/CredbullBaseVault.sol";

abstract contract MaturityVault is CredbullBaseVault {
    using Math for uint256;

    struct MaturityVaultParams {
        BaseVaultParams baseVaultParams;
        uint256 promisedYield;
    }

    /// @notice Reverts on withdraw if vault is not matured.
    error CredbullVault__NotMatured();

    /// @notice Reverts on mature if there is not enough balance.
    error CredbullVault__NotEnoughBalanceToMature();

    /// @notice Determine if the vault is matured or not.
    bool public isMatured;

    /// @notice Determine if Maturity Checking is enabled or disabled.
    bool public checkMaturity;

    /// @dev The fixed yield value in percentage(100) that's promised to the users on deposit.
    uint256 private _fixedYield;

    constructor(MaturityVaultParams memory params) CredbullBaseVault(params.baseVaultParams) {
        checkMaturity = true;
        _fixedYield = params.promisedYield;
    }

    /// @notice - Returns expected assets on maturity
    function expectedAssetsOnMaturity() public view returns (uint256) {
        return totalAssetDeposited.mulDiv(100 + _fixedYield, 100);
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
