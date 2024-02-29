import { CredbullSDK } from "..";
import { login, signer, __mockMint } from './utils/helpers';
import { BigNumber } from 'ethers';

import { config } from 'dotenv';

config();


(async () => {
  //Login to get access token
  const res = await login('krishnakumar@ascent-hr', '1.ql8lo3qdok');
  //Signer or Provider
  const userSigner = signer(process.env.ADMIN_PRIVATE_KEY || "0x");

  // Initialize the SDK
  const sdk = new CredbullSDK(res.access_token, userSigner);

  //Get all vaults through SDK
  const vaults = await sdk.getAllVaults();
  console.log(vaults);

  //Link wallet through SDK
  await sdk.linkWallet();

  //Prepare for deposit
  const vaultAddress = vaults.data ? vaults.data[0].address : "";

  const vault = await sdk.getVaultInstance(vaultAddress);
  const usdc = await sdk.getAssetInstance(vaultAddress);

  const depositAmount = BigNumber.from('100000000');

  //Prepare for deposit - Only for testing to mints asset token
  if(process.env.NODE_ENV === 'development') {
    console.log('in node env dev')
    await __mockMint(userSigner.address, depositAmount.mul(2), vault, userSigner);
  }

  await usdc.approve(vaultAddress, depositAmount);

  //Deposit through SDK
  await sdk.deposit(vaultAddress, depositAmount, userSigner.address);

  const shares = BigNumber.from('100000000');

  console.log((await vault.balanceOf(userSigner.address)).toString());

  //Only for testing, premint tokens and do admin ops
  if(process.env.NODE_ENV === 'development') {
    await __mockMint(vaultAddress, depositAmount, vault, userSigner);
    //Skipping window check
    await vault.toggleWindowCheck(false);
    await vault.toggleMaturityCheck(false);
  }

  //Redeem through SDK
  await sdk.redeem(vaultAddress, shares, userSigner.address);

  console.log((await vault.balanceOf(userSigner.address)).toString());

})();
