import { config } from 'dotenv';
import { BigNumber } from 'ethers';

import { CredbullSDK } from '../../../src/index';

import { __mockMint, login, signer } from './utils/helpers';

config();

(async () => {
  // Login to get access token
  const res = await login('krishnakumar@ascent-hr', '1.ql8lo3qdok');
  console.log(res);
  // Signer or Provider
  const userSigner = signer(process.env.ADMIN_PRIVATE_KEY || '0x');

  const userAddress = await userSigner.getAddress();
  // Initialize the SDK
  const sdk = new CredbullSDK(process.env.BASE_URL || '', res.access_token, userSigner);

  //Get all vaults through SDK
  const vaults = await sdk.getAllVaults();
  console.log(vaults);

  // Link wallet through SDK
  await sdk.linkWallet();

  //Prepare for deposit
  const vaultAddress = vaults.data ? vaults.data[0].address : '';

  const vault = await sdk.getVaultInstance(vaultAddress);
  const usdc = await sdk.getAssetInstance(vaultAddress);

  const depositAmount = BigNumber.from('100000000');

  // Prepare for deposit - Only for testing to mints asset token
  if (process.env.NODE_ENV === 'development') {
    await __mockMint(userAddress, depositAmount.mul(2), vault, userSigner);
  }

  await usdc.approve(vaultAddress, depositAmount);

  // Deposit through SDK
  await sdk.deposit(vaultAddress, depositAmount, userAddress);

  const shares = BigNumber.from('100000000');

  console.log((await vault.balanceOf(userAddress)).toString());

  // Only for testing, premint tokens and do admin ops
  if (process.env.NODE_ENV === 'development') {
    await __mockMint(vaultAddress, depositAmount, vault, userSigner);
    //Skipping window check
    await vault.toggleWindowCheck(false);
    await vault.toggleMaturityCheck(false);
  }

  // Redeem through SDK
  await sdk.redeem(vaultAddress, shares, userAddress);

  console.log((await vault.balanceOf(userAddress)).toString());
})();
