// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

// import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// TODO - extend IERC165
interface ITenorable {
    /*
     * The number of timePeriods for holding an asset to maturity
     */
    function getTenor() external view returns (uint256 tenor);
}
