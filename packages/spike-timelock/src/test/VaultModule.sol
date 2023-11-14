// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import "zodiac/core/Module.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract VaultModule is Module {
    address public vault;

    constructor(address _owner, address _vault) {
        bytes memory initializeParams = abi.encode(_owner, _vault);
        setUp(initializeParams);
    }

    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init(_msgSender());

        (address _owner, address _vault) = abi.decode(initializeParams, (address, address));

        vault = _vault;
        setAvatar(_owner);
        setTarget(_owner);
        transferOwnership(_owner);
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        (,bytes memory data) = execAndReturnData(vault, 0, abi.encodeWithSignature("withdraw(uint256,address,address)", assets, receiver, owner), Enum.Operation.Call);
        return abi.decode(data, (uint256));
    }

    function redeem(uint256 shares, address receiver, address owner) external returns (uint256) {
        (,bytes memory data) = execAndReturnData(vault, 0, abi.encodeWithSignature("redeem(uint256,address,address)", shares, receiver, owner), Enum.Operation.Call);
        return abi.decode(data, (uint256));
    }
}
