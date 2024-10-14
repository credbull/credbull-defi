//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

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
    AnvilWallet private _alice = new AnvilWallet(7);
    AnvilWallet private _bob = new AnvilWallet(8);
    AnvilWallet private _charlie = new AnvilWallet(9);

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
        _loadDepositsAndRequestSells(vault, _alice, 10);
        _loadDepositsAndRequestSells(vault, _bob, 1);
        _loadDepositsAndRequestSells(vault, _charlie, 2);

        return vault;
    }

    function _loadDepositsAndRequestSells(
        LiquidContinuousMultiTokenVault vault,
        AnvilWallet userWallet,
        uint256 userDepositMultiplier
    ) internal {
        IERC20 asset = IERC20(vault.asset());
        uint256 scale = 10 ** IERC20Metadata(vault.asset()).decimals();

        // --------------------- gift user funds ---------------------

        vm.startBroadcast(_owner.key());
        asset.transfer(userWallet.addr(), 1_000_000 * scale);
        vm.stopBroadcast();

        // --------------------- load deposits ---------------------
        uint256 baseDepositAmount = 100 * scale * userDepositMultiplier;

        uint256 prevSupply = vault.totalSupply();

        console2.log("Depositing for %s", userWallet.addr());

        uint256 totalUserDeposits = 0;

        for (uint256 depositPeriod = 0; depositPeriod <= vault.TENOR(); ++depositPeriod) {
            // first set the start time / period as operator
            _setPeriod(vault, depositPeriod);

            if (depositPeriod % 7 == 0) {
                // skip deposits every 7th day
                continue;
            }

            vm.startBroadcast(userWallet.key());

            // --------------------- deposits ---------------------
            uint256 depositAmount = baseDepositAmount * vault.currentPeriod();
            asset.approve(address(vault), depositAmount);
            vault.executeBuy(userWallet.addr(), 0, depositAmount, depositAmount);
            totalUserDeposits += depositAmount;

            // --------------------- request sell ---------------------
            if (vault.currentPeriod() == vault.TENOR() - 1) {
                // queue up one request only
                vault.requestSell(totalUserDeposits / 10);
            }

            vm.stopBroadcast();
        }

        console2.log("VaultSupply after deposits %s -> %s", prevSupply, vault.totalSupply());
    }

    function _setPeriod(LiquidContinuousMultiTokenVault vault, uint256 newPeriod) public {
        uint256 prevPeriod = vault.currentPeriod();
        uint256 newPeriodInSeconds = newPeriod * 1 days;
        uint256 currentTime = Timer.timestamp();

        uint256 newStartTime =
            currentTime > newPeriodInSeconds ? (currentTime - newPeriodInSeconds) : (newPeriodInSeconds - currentTime);

        vm.startBroadcast(_operator.key());
        vault.setVaultStartTimestamp(newStartTime);
        vm.stopBroadcast();

        console2.log("VaultCurrentPeriod updated %s -> %s", prevPeriod, vault.currentPeriod());
    }
}

//Anvil Accounts
//==================
//(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH) - owner
//(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH) - operator
//(2) 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000 ETH) - custody (vault->custody->vault)
//(3) 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000 ETH) - treasury
//(4) 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (10000 ETH) - deployer
//(5) 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (10000 ETH) - rewards
//(6) 0x976EA74026E726554dB657fA54763abd0C3a0aa9 (10000 ETH) - (available)
//(7) 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 (10000 ETH) - alice
//(8) 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f (10000 ETH) - bob
//(9) 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 (10000 ETH) - charlie
contract AnvilWallet is Script {
    uint32 private index;

    constructor(uint32 index_) {
        index = index_;
    }

    function addr() public view returns (address) {
        return vm.addr(key());
    }

    function key() public view returns (uint256 privateKey) {
        string memory mnemonic = "test test test test test test test test test test test junk";

        return vm.deriveKey(mnemonic, index);
    }
}
