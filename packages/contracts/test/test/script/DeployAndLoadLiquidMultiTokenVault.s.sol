//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { console2 } from "forge-std/console2.sol";
import { Script } from "forge-std/Script.sol";

/*
Requirements
   Start the vault as of 30 days ago (at 12:00 noon EST.  Run in the following for multiple users:
   - Deposits at -1 minute and +1 minute
   - Request sells (and sells?) at -1 minute and +1 minute
*/
contract DeployAndLoadLiquidMultiTokenVault is DeployLiquidMultiTokenVault {
    using SafeERC20 for IERC20;

    Chain private _chain;

    AnvilWallet private _owner = new AnvilWallet(0);
    AnvilWallet private _operator = new AnvilWallet(1);
    AnvilWallet private _alice = new AnvilWallet(8);
    AnvilWallet private _bob = new AnvilWallet(9);

    error AnvilChainOnly(uint256 actualChainId, uint256 expectedChainId);
    error OwnerMismatch(address actualOwner, address expectedOwner);

    constructor() {
        uint256 anvilChainId = 31337;

        if (block.chainid != anvilChainId) {
            revert AnvilChainOnly(block.chainid, anvilChainId);
        }

        _chain = getChain(anvilChainId);
    }

    function run(LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth)
        public
        override
        returns (LiquidContinuousMultiTokenVault vault_)
    {
        // deploy
        LiquidContinuousMultiTokenVault vault = super.run(vaultAuth);

        console2.log("===============================");
        console2.log("loading test data...");
        console2.log("===============================");

        if (vaultAuth.owner != _owner.addr()) {
            revert OwnerMismatch(vaultAuth.owner, _owner.addr());
        }

        // --------------------- load deposits ---------------------
        _loadDepositsAndRequestSells(vault, _alice);

        return vault;
    }

    function _loadDepositsAndRequestSells(LiquidContinuousMultiTokenVault vault, AnvilWallet userWallet) internal {
        IERC20 asset = IERC20(vault.asset());
        uint256 scale = 10 ** IERC20Metadata(vault.asset()).decimals();

        // --------------------- rewind the clock ---------------------
        uint256 tenorDaysAgo = block.timestamp - (vault.TENOR() * 1 days);
        _setVaultStartTime(vault, tenorDaysAgo);

        // --------------------- gift user funds ---------------------

        vm.startBroadcast(_owner.key());
        asset.transfer(userWallet.addr(), 100_000 * scale);
        vm.stopBroadcast();

        // --------------------- load deposits ---------------------
        uint256 baseDepositAmount = 100 * scale;

        uint256 prevSupply = vault.totalSupply();

        console2.log("Depositing for %s", userWallet.addr());

        uint256 totalUserDeposits = 0;

        for (uint256 i = 0; i < vault.TENOR(); ++i) {
            vm.startBroadcast(userWallet.key());

            // --------------------- deposits ---------------------
            uint256 depositAmount = baseDepositAmount * vault.currentPeriod();
            asset.approve(address(vault), depositAmount);
            vault.executeBuy(userWallet.addr(), 0, depositAmount, depositAmount);

            // --------------------- request sells ---------------------

            if (vault.currentPeriod() > vault.TENOR() - 5) {
                // only request for the last few days - the rest won't help
                vault.requestSell(totalUserDeposits / 10); // request to sell 10% of deposits so far
            }

            vm.stopBroadcast();

            totalUserDeposits += depositAmount;
            _setVaultStartTime(vault, vault._vaultStartTimestamp() + (1 days));
        }

        console2.log("VaultSupply after deposits %s -> %s", prevSupply, vault.totalSupply());

        // to use the deposits - we need the start time back tenor days ago
        _setVaultStartTime(vault, tenorDaysAgo);
    }

    function _setVaultStartTime(LiquidContinuousMultiTokenVault vault, uint256 startTimeStamp) internal {
        uint256 prevPeriod = vault.currentPeriod();

        vm.startBroadcast(_operator.key());
        vault.setVaultStartTimestamp(startTimeStamp);
        vm.stopBroadcast();

        console2.log("VaultCurrentPeriod updated %s -> %s", prevPeriod, vault.currentPeriod());
    }
}

contract AnvilWallet is Script {
    uint32 private index;

    constructor(uint32 index_) {
        index = index_;
    }

    function addr() public returns (address) {
        return vm.addr(key());
    }

    function key() public returns (uint256 privateKey) {
        string memory mnemonic = "test test test test test test test test test test test junk";

        return vm.deriveKey(mnemonic, index);
    }
}
