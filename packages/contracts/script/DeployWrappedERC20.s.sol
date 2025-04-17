//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { WrappedERC20 } from "@credbull/token/ERC20/WrappedERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { TomlConfig, stdToml } from "@script/TomlConfig.s.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployWrappedERC20 is TomlConfig {
    using stdToml for string;

    string private _symbolPostfix = "";

    string private _tomlConfig;

    constructor() {
        _tomlConfig = loadTomlConfiguration();
    }

    function run() public returns (WrappedERC20 wrappedToken) {
        address owner = cblOwnerFromConfig();
        IERC20Metadata underlyingToken = cblTokenFromConfig();

        WrappedERC20.Params memory params = createParams(owner, underlyingToken);

        return run(params);
    }

    function run(WrappedERC20.Params memory params) public returns (WrappedERC20 wrappedToken) {
        vm.startBroadcast();

        wrappedToken = new WrappedERC20(params);
        console2.log(string.concat("!!!!! Deploying WrappedERC20 [", vm.toString(address(wrappedToken)), "] !!!!!"));
        vm.stopBroadcast();

        return wrappedToken;
    }

    function cblOwnerFromConfig() internal view returns (address owner) {
        return _tomlConfig.readAddress(".evm.contracts.cbl.owner");
    }

    function cblTokenFromConfig() internal view returns (IERC20Metadata underlyingToken) {
        return IERC20Metadata(_tomlConfig.readAddress(".evm.address.cbl_token"));
    }

    function createParams(address owner, IERC20Metadata underlyingToken)
        public
        view
        returns (WrappedERC20.Params memory params_)
    {
        string memory name = string.concat("Wrapped ", underlyingToken.name(), _symbolPostfix);
        string memory symbol = string.concat("w", underlyingToken.symbol(), _symbolPostfix);

        WrappedERC20.Params memory tokenParams =
            WrappedERC20.Params({ owner: owner, name: name, symbol: symbol, underlyingToken: underlyingToken });

        return tokenParams;
    }

    function setPostfix(string memory newSymbolPostfix) public {
        _symbolPostfix = newSymbolPostfix;
    }
}
