//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/SimpleUSDC.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { TomlConfig } from "@script/TomlConfig.s.sol";
import { stdToml } from "forge-std/StdToml.sol";

contract DeployScript is ScaffoldETHDeploy, TomlConfig {
    using stdToml for string;

    error InvalidPrivateKey(string);

    string private tomlConfig;

    address private owner;
    address private operator;

    constructor() {
        tomlConfig = loadTomlConfiguration();

        owner = tomlConfig.readAddress(".evm.address.owner");
        operator = tomlConfig.readAddress(".evm.address.operator");
    }

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");

        if (deployerPrivateKey == 0) {
            revert InvalidPrivateKey(
                "You don't have a deployer account. Make sure you have set DEPLOYER_PRIVATE_KEY in .env or use `yarn generate` to generate a new random account"
            );
        }

        vm.startBroadcast(deployerPrivateKey);

        SimpleUSDC simpleUSDC = _deploySimpleUSDC();

        vm.stopBroadcast();

        vm.startBroadcast(userPrivateKey);

        _mintUserTokens(simpleUSDC, owner);

        vm.stopBroadcast();

        exportDeployments(); // Export ABI definitions
    }

    function _deploySimpleUSDC() internal returns (SimpleUSDC) {
        uint256 INITIAL_SUPPLY = 10_000_000 * (10 ** 6); // 10 million, scaled
        SimpleUSDC simpleUSDC = new SimpleUSDC(INITIAL_SUPPLY);
        console.logString(string.concat("SimpleUSDC deployed at: ", vm.toString(address(simpleUSDC))));
        return simpleUSDC;
    }

    function _mintUserTokens(SimpleUSDC simpleUSDC, address _owner) internal {
        uint256 SCALE = 10 ** simpleUSDC.decimals();
        uint256 userMintAmount = 100_000 * SCALE;
        simpleUSDC.mint(_owner, userMintAmount);
    }
}
