"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const __1 = require("..");
const helpers_1 = require("./utils/helpers");
const ethers_1 = require("ethers");
const dotenv_1 = require("dotenv");
(0, dotenv_1.config)();
(() => __awaiter(void 0, void 0, void 0, function* () {
    //Login to get access token
    const res = yield (0, helpers_1.login)('krishnakumar@ascent-hr', '1.ql8lo3qdok');
    //Signer or Provider
    const userSigner = (0, helpers_1.signer)(process.env.ADMIN_PRIVATE_KEY || '0x');
    const userAddress = yield userSigner.getAddress();
    // Initialize the SDK
    const sdk = new __1.CredbullSDK(res.access_token, userSigner);
    //Get all vaults through SDK
    const vaults = yield sdk.getAllVaults();
    console.log(vaults);
    //Link wallet through SDK
    yield sdk.linkWallet();
    //Prepare for deposit
    const vaultAddress = vaults.data ? vaults.data[0].address : '';
    const vault = yield sdk.getVaultInstance(vaultAddress);
    const usdc = yield sdk.getAssetInstance(vaultAddress);
    const depositAmount = ethers_1.BigNumber.from('100000000');
    //Prepare for deposit - Only for testing to mints asset token
    if (process.env.NODE_ENV === 'development') {
        yield (0, helpers_1.__mockMint)(userAddress, depositAmount.mul(2), vault, userSigner);
    }
    yield usdc.approve(vaultAddress, depositAmount);
    //Deposit through SDK
    yield sdk.deposit(vaultAddress, depositAmount, userAddress);
    const shares = ethers_1.BigNumber.from('100000000');
    console.log((yield vault.balanceOf(userAddress)).toString());
    //Only for testing, premint tokens and do admin ops
    if (process.env.NODE_ENV === 'development') {
        yield (0, helpers_1.__mockMint)(vaultAddress, depositAmount, vault, userSigner);
        //Skipping window check
        yield vault.toggleWindowCheck(false);
        yield vault.toggleMaturityCheck(false);
    }
    //Redeem through SDK
    yield sdk.redeem(vaultAddress, shares, userAddress);
    console.log((yield vault.balanceOf(userAddress)).toString());
}))();
