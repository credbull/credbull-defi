//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DeployHelpers.s.sol";
import "../contracts/SimpleUSDC.sol";
import "../contracts/yield/LiquidContinuousMultiTokenVault.sol";
import "../contracts/yield/strategy/TripleRateYieldStrategy.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";

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
        LiquidContinuousMultiTokenVault vault = _deployLiquidContinuousVault(simpleUSDC);

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

    function _deployLiquidContinuousVault(SimpleUSDC simpleUSDC) internal returns (LiquidContinuousMultiTokenVault) {
        uint256 SCALE = 10 ** simpleUSDC.decimals();

        uint256 fullRateBasisPoints = _readUintFromToml(".full_rate_bps");
        uint256 reducedRateBasisPoints = _readUintFromToml(".reduced_rate_bps");

        TripleRateContext.ContextParams memory contextParams = TripleRateContext.ContextParams({
            fullRateScaled: fullRateBasisPoints * SCALE / 100,
            initialReducedRate: ITripleRateContext.PeriodRate({
                interestRate: reducedRateBasisPoints * SCALE / 100,
                effectiveFromPeriod: 0
            }),
            frequency: 365,
            tenor: 30,
            decimals: simpleUSDC.decimals()
        });

        uint256 startTimestamp = _readUintWithDefault(tomlConfig, ".vault_start_timestamp", block.timestamp);

        LiquidContinuousMultiTokenVault.VaultParams memory params = LiquidContinuousMultiTokenVault.VaultParams({
            contractOwner: owner,
            contractOperator: operator,
            asset: simpleUSDC,
            yieldStrategy: _deployYieldStrategy(),
            redeemOptimizer: _deployRedeemOptimizer(),
            vaultStartTimestamp: startTimestamp,
            redeemNoticePeriod: 1,
            contextParams: contextParams
        });

        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault();
        vault.initialize(params);
        return vault;
    }

    function _deployYieldStrategy() internal returns (IYieldStrategy) {
        return new TripleRateYieldStrategy();
    }

    function _deployRedeemOptimizer() internal returns (IRedeemOptimizer) {
        return new RedeemOptimizerFIFO();
    }

    function _mintUserTokens(SimpleUSDC simpleUSDC, address _owner) internal {
        uint256 SCALE = 10 ** simpleUSDC.decimals();
        uint256 userMintAmount = 100_000 * SCALE;
        simpleUSDC.mint(_owner, userMintAmount);
    }

    function _readUintFromToml(string memory keySuffix) internal view returns (uint256) {
        string memory contractKey = ".evm.contracts.liquid_continuous_multi_token_vault";
        return tomlConfig.readUint(string.concat(contractKey, keySuffix));
    }
}
