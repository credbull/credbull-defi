import { config } from 'dotenv';
import { BigNumber, utils } from 'ethers';

import { CredbullSDK } from '../../../src/index';
import { __mockMint, generateSigner, login, signer } from './utils/helpers';

config();

(async () => {
  //Login to get access token
  const res = await login('krishnakumar@ascent-hr', '1.ql8lo3qdok');

  //Signer or Provider
  //TODO: Replace it with privatekey from env
  const user1Signer = generateSigner();
  const user2Signer = generateSigner();
  const admin = signer(process.env.ADMIN_PRIVATE_KEY || '0x');

  //Send ETH to users to do txns
  const tx1 = {
    to: user1Signer.address,
    value: utils.parseEther('0.01'),
  };
  const tx2 = {
    to: user2Signer.address,
    value: utils.parseEther('0.01'),
  };
  await admin.sendTransaction(tx1);
  await admin.sendTransaction(tx2);

  // Initialize the SDK
  const sdkUser1 = new CredbullSDK(process.env.BASE_URL || '', res.access_token, user1Signer);
  const sdkUser2 = new CredbullSDK(process.env.BASE_URL || '', res.access_token, user2Signer);

  //Get all vaults through SDK
  const vaults = await sdkUser1.getAllVaults();
  console.log(vaults);

  //Link wallet through SDK
  await sdkUser1.linkWallet();
  await sdkUser2.linkWallet();

  //Prepare for deposit
  const vaultAddress = vaults.data ? vaults.data[0].address : '';
  const vault = await sdkUser1.getVaultInstance(vaultAddress);

  const depositAmount = BigNumber.from('100000000');

  //Mock mint for users - only for testing
  if (process.env.NODE_ENV === 'development') {
    await __mockMint(user1Signer.address, depositAmount, vault, user1Signer);
    await __mockMint(user2Signer.address, depositAmount, vault, user2Signer);
  }

  const usdc = await sdkUser1.getAssetInstance(vaultAddress);

  await usdc.connect(user1Signer).approve(vaultAddress, depositAmount);
  await usdc.connect(user2Signer).approve(vaultAddress, depositAmount);

  //Deposit through SDK
  await sdkUser1.deposit(vaultAddress, depositAmount, user1Signer.address);
  await sdkUser2.deposit(vaultAddress, depositAmount, user2Signer.address);

  console.log('========================== Deposit completed! =====================');
  console.log('User1 Shares:', (await vault.balanceOf(user1Signer.address)).toString());
  console.log('User2 Shares:', (await vault.balanceOf(user2Signer.address)).toString());

  const shares = depositAmount;

  //Only for testing - Mature vault and other admin ops
  if (process.env.NODE_ENV === 'development') {
    await __mockMint(vaultAddress, depositAmount.mul(2), vault, user1Signer);
    //Skipping window check
    await vault.connect(admin).toggleWindowCheck(false);
    await vault.connect(admin).toggleMaturityCheck(false);
  }

  //Redeem through SDK
  await sdkUser1.redeem(vaultAddress, shares, user1Signer.address);
  await sdkUser2.redeem(vaultAddress, shares, user2Signer.address);
  console.log((await usdc.balanceOf(user1Signer.address)).toString());
  console.log('========================== Redeem completed! =====================');
  console.log('User1 Shares:', (await vault.balanceOf(user1Signer.address)).toString());
  console.log('User2 Shares:', (await vault.balanceOf(user2Signer.address)).toString());
})();
