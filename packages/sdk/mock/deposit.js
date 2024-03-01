'use strict';
var __awaiter =
  (this && this.__awaiter) ||
  function (thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P
        ? value
        : new P(function (resolve) {
            resolve(value);
          });
    }
    return new (P || (P = Promise))(function (resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator['throw'](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
Object.defineProperty(exports, '__esModule', { value: true });
const dotenv_1 = require('dotenv');
const ethers_1 = require('ethers');
const __1 = require('..');
const helpers_1 = require('./utils/helpers');
(0, dotenv_1.config)();
(() =>
  __awaiter(void 0, void 0, void 0, function* () {
    //Login to get access token
    const res = yield (0, helpers_1.login)('krishnakumar@ascent-hr', '1.ql8lo3qdok');
    //Signer or Provider
    //TODO: Replace it with privatekey from env
    const user1Signer = (0, helpers_1.generateSigner)();
    const user2Signer = (0, helpers_1.generateSigner)();
    const admin = (0, helpers_1.signer)(process.env.ADMIN_PRIVATE_KEY || '0x');
    //Send ETH to users to do txns
    const tx1 = {
      to: user1Signer.address,
      value: ethers_1.utils.parseEther('0.01'),
    };
    const tx2 = {
      to: user2Signer.address,
      value: ethers_1.utils.parseEther('0.01'),
    };
    yield admin.sendTransaction(tx1);
    yield admin.sendTransaction(tx2);
    // Initialize the SDK
    const sdkUser1 = new __1.CredbullSDK(res.access_token, user1Signer);
    const sdkUser2 = new __1.CredbullSDK(res.access_token, user2Signer);
    //Get all vaults through SDK
    const vaults = yield sdkUser1.getAllVaults();
    console.log(vaults);
    //Link wallet through SDK
    yield sdkUser1.linkWallet();
    yield sdkUser2.linkWallet();
    //Prepare for deposit
    const vaultAddress = vaults.data ? vaults.data[0].address : '';
    const vault = yield sdkUser1.getVaultInstance(vaultAddress);
    const depositAmount = ethers_1.BigNumber.from('100000000');
    //Mock mint for users - only for testing
    if (process.env.NODE_ENV === 'development') {
      yield (0, helpers_1.__mockMint)(user1Signer.address, depositAmount, vault, user1Signer);
      yield (0, helpers_1.__mockMint)(user2Signer.address, depositAmount, vault, user2Signer);
    }
    const usdc = yield sdkUser1.getAssetInstance(vaultAddress);
    yield usdc.connect(user1Signer).approve(vaultAddress, depositAmount);
    yield usdc.connect(user2Signer).approve(vaultAddress, depositAmount);
    //Deposit through SDK
    yield sdkUser1.deposit(vaultAddress, depositAmount, user1Signer.address);
    yield sdkUser2.deposit(vaultAddress, depositAmount, user2Signer.address);
    console.log('========================== Deposit completed! =====================');
    console.log('User1 Shares:', (yield vault.balanceOf(user1Signer.address)).toString());
    console.log('User2 Shares:', (yield vault.balanceOf(user2Signer.address)).toString());
    const shares = depositAmount;
    //Only for testing - Mature vault and other admin ops
    if (process.env.NODE_ENV === 'development') {
      yield (0, helpers_1.__mockMint)(vaultAddress, depositAmount.mul(2), vault, user1Signer);
      //Skipping window check
      yield vault.connect(admin).toggleWindowCheck(false);
      yield vault.connect(admin).toggleMaturityCheck(false);
    }
    //Redeem through SDK
    yield sdkUser1.redeem(vaultAddress, shares, user1Signer.address);
    yield sdkUser2.redeem(vaultAddress, shares, user2Signer.address);
    console.log((yield usdc.balanceOf(user1Signer.address)).toString());
    console.log('========================== Redeem completed! =====================');
    console.log('User1 Shares:', (yield vault.balanceOf(user1Signer.address)).toString());
    console.log('User2 Shares:', (yield vault.balanceOf(user2Signer.address)).toString());
  }))();
