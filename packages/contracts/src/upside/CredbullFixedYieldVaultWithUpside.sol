// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

pragma solidity ^0.8.19;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { FixedYieldVault } from "../FixedYieldVault.sol";
import { ParentLinkPlugIn } from "../plugins/ParentLinkPlugIn.sol";

contract CredbullFixedYieldVaultWithUpside is FixedYieldVault {
    using Math for uint256;

    address public linkedVault;

    uint256 public twap = 1;
    uint256 public collateralPercentage;

    constructor(VaultParams memory params, address _linkedVault, uint256 _collateralPercentage)
        FixedYieldVault(params)
    {
        collateralPercentage = _collateralPercentage;
        linkedVault = _linkedVault;
        ParentLinkPlugIn(linkedVault).setParentLink(address(this));
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets.mulDiv(collateralPercentage, 100) / twap, receiver);
        IERC4626(linkedVault).deposit(assets, receiver);

        return shares;
    }

    function mint(uint256 shares, address receiver) public override returns (uint256) {
        uint256 assets = shares.mulDiv(twap, collateralPercentage / 100);

        super.deposit(assets, receiver);
        IERC4626(linkedVault).deposit(assets, receiver);

        return assets;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        uint256 assets = super.redeem(shares, receiver, owner);
        IERC4626(linkedVault).redeem(shares, receiver, owner);

        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        uint256 shares = super.withdraw(assets, receiver, owner);
        IERC4626(linkedVault).withdraw(assets, receiver, owner);

        return shares;
    }

    function setTWAP(uint256 _twap) public onlyRole(OPERATOR_ROLE) {
        twap = _twap;
    }
}
