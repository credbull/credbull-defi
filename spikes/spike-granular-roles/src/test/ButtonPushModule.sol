// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import "zodiac/core/Module.sol";

contract ButtonPushModule is Module {
    address public button;

    constructor(address _owner, address _button) {
        bytes memory initializeParams = abi.encode(_owner, _button);
        setUp(initializeParams);
    }

    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();

        (address _owner, address _button) = abi.decode(initializeParams, (address, address));

        button = _button;
        setAvatar(_owner);
        setTarget(_owner);
        transferOwnership(_owner);
    }

    function pushButton() external {
        exec(button, 0, abi.encodePacked(bytes4(keccak256("pushButton()"))), Enum.Operation.Call);
    }

    function pushes() public returns (uint256 count) {
        (,bytes memory data) = execAndReturnData(button, 0, abi.encodePacked(bytes4(keccak256("pushes()"))), Enum.Operation.Call);
        return abi.decode(data, (uint256));
    }
}
