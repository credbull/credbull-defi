//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../base/CredbullBaseVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

abstract contract MaturityVault is CredbullBaseVault {
    using Math for uint256;

    //Error to revert on withdraw if vault is not matured
    error CredbullVault__NotMatured();
    //Error to revert mature if there is not enough balance to mature
    error CredbullVault__NotEnoughBalanceToMature();

    /**
     * @notice - Track if vault is matured
     */
    bool public isMatured;

    bool public checkMaturity;

    /**
     * @dev
     * The fixed yield that's promised to the users on deposit.
     */
    uint256 private _fixedYield;

    constructor(VaultParams memory params) CredbullBaseVault(params) {
        checkMaturity = true;
        _fixedYield = params.promisedYield;
    }

    /**
     * @notice - Returns expected assets on maturity
     */
    function expectedAssetsOnMaturity() public view returns (uint256) {
        return totalAssetDeposited.mulDiv(100 + _fixedYield, 100);
    }

    /**
     * @notice - A method to mature the vault after the assets that was deposited from the custodian wallet with addition yield earned.
     * @dev - _totalAssetDeposited to be updated to calculate the right amount of asset with yield in proportion to the shares received.
     */
    function _mature() internal {
        uint256 currentBalance = IERC20(asset()).balanceOf(address(this));

        if (this.expectedAssetsOnMaturity() > currentBalance) {
            revert CredbullVault__NotEnoughBalanceToMature();
        }

        totalAssetDeposited = currentBalance;
        isMatured = true;
    }

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

    function _toogleMaturityCheck(bool status) internal {
        checkMaturity = status;
    }
}
