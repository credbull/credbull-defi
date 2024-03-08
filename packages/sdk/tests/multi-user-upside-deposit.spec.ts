// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { config } from 'dotenv';
import { BigNumber, Signer } from 'ethers';

import { CredbullSDK } from '../index';
import { signer } from '../mock/utils/helpers';

import { __mockMint, __mockMintToken, login, toggleWindowCheck, toggleMaturityCheck } from './utils/admin-ops';

config();

let walletSignerA: Signer | undefined = undefined;
let walletSignerB: Signer | undefined = undefined;
let sdkA: CredbullSDK;
let sdkB: CredbullSDK;

let userAddressA: string;
let userAddressB: string;

let vaultAddress: string;

test.beforeAll(async () => {
  const { access_token: userAToken } = await login(process.env.USER_A_EMAIL || '', process.env.USER_A_PASSWORD || '');
  const { access_token: userBToken } = await login(process.env.USER_B_EMAIL || '', process.env.USER_B_PASSWORD || '');

  walletSignerA = signer(process.env.USER_A_PRIVATE_KEY || '0x');
  walletSignerB = signer(process.env.USER_B_PRIVATE_KEY || '0x');

  sdkA = new CredbullSDK(userAToken, walletSignerA as Signer);
  sdkB = new CredbullSDK(userBToken, walletSignerB as Signer);

  userAddressA = await (walletSignerA as Signer).getAddress();
  userAddressB = await (walletSignerB as Signer).getAddress();

  //link wallet
  await sdkA.linkWallet();
  await sdkB.linkWallet();
});

test.describe('Multi user Interaction - Upside', async () => {
  test('Deposit and redeem flow', async () => {
    const depositAmount = BigNumber.from('100000000');

    await test.step('Get all vaults and filter upside', async () => {
      const vaults = await sdkA.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const upsideVault = vaults.data.find((vault: any) => vault.type === 'fixed_yield_upside');
      expect(upsideVault).toBeTruthy();

      vaultAddress = upsideVault.address;

      return upsideVault;
    });

    //MINT USDC for user
    const collateralRequired = await test.step('MINT USDC and CBL token for user', async () => {
      const vault = await sdkA.getUpsideVaultInstance(vaultAddress);

      const collateralRequired = await vault.getCollateralAmount(depositAmount);

      await __mockMintToken(await (walletSignerA as Signer).getAddress(), collateralRequired, vault, walletSignerA as Signer);
      await __mockMintToken(await (walletSignerB as Signer).getAddress(), collateralRequired, vault, walletSignerB as Signer);

      await __mockMint(await (walletSignerA as Signer).getAddress(), depositAmount, vault, walletSignerA as Signer);
      await __mockMint(await (walletSignerB as Signer).getAddress(), depositAmount, vault, walletSignerB as Signer);

      return collateralRequired;
    });

    //Get approval for deposit
    await test.step('Get approval for deposit', async () => {
      const usdc = await sdkA.getAssetInstance(vaultAddress);
      await usdc.connect(walletSignerA as Signer).approve(vaultAddress, depositAmount);
      await usdc.connect(walletSignerB as Signer).approve(vaultAddress, depositAmount);

      const token = await sdkA.getTokenInstance(vaultAddress);
      await token.connect(walletSignerA as Signer).approve(vaultAddress, collateralRequired);
      await token.connect(walletSignerB as Signer).approve(vaultAddress, collateralRequired);

      const tokenApprovalA = await token.allowance(await (walletSignerA as Signer).getAddress(), vaultAddress);
      const tokenApprovalB = await token.allowance(await (walletSignerB as Signer).getAddress(), vaultAddress);

      expect(tokenApprovalA.toString()).toEqual(collateralRequired.toString());
      expect(tokenApprovalB.toString()).toEqual(collateralRequired.toString());

      const approvalA = await usdc.allowance(await (walletSignerA as Signer).getAddress(), vaultAddress);
      const approvalB = await usdc.allowance(await (walletSignerB as Signer).getAddress(), vaultAddress);
      expect(approvalA.toString()).toEqual(depositAmount.toString());
      expect(approvalB.toString()).toEqual(depositAmount.toString());
    });

    //Deposit through SDK
    await test.step('Deposit through SDK', async () => {
      const vault = await sdkA.getUpsideVaultInstance(vaultAddress);
      const token = await sdkA.getTokenInstance(vaultAddress);

      const shareBalanceBeforeDepositA = await vault.balanceOf(userAddressA);
      const shareBalanceBeforeDepositB = await vault.balanceOf(userAddressB);

      const vaultTokenBalanceBeforeDeposit = await token.balanceOf(vaultAddress);

      await sdkA.deposit(vaultAddress, depositAmount, userAddressA);
      await sdkB.deposit(vaultAddress, depositAmount, userAddressB);

      const shareBalanceAfterDepositA = await vault.balanceOf(userAddressA);
      const shareBalanceAfterDepositB = await vault.balanceOf(userAddressB);

      const vaultTokenBalanceAfterDeposit = await token.balanceOf(vaultAddress);

      expect(vaultTokenBalanceBeforeDeposit.add(collateralRequired.mul(2)).toString()).toEqual(vaultTokenBalanceAfterDeposit.toString());

      expect(shareBalanceBeforeDepositA.add(depositAmount).toString()).toEqual(shareBalanceAfterDepositA.toString());
      expect(shareBalanceBeforeDepositB.add(depositAmount).toString()).toEqual(shareBalanceAfterDepositB.toString());
    });

    //Redeem through SDK
    await test.step('Redeem through SDK', async () => {
      const vault = await sdkA.getUpsideVaultInstance(vaultAddress);
      const token = await sdkA.getTokenInstance(vaultAddress);

      //Mature vault
      await __mockMint(vaultAddress, depositAmount.mul(2), vault, walletSignerA as Signer);

      const shares = depositAmount;
      const shareBalanceBeforeRedeemA = await vault.balanceOf(userAddressA);
      const shareBalanceBeforeRedeemB = await vault.balanceOf(userAddressB);

      const tokenBalanceBeforeRedeemA = await token.balanceOf(userAddressA);
      const tokenBalanceBeforeRedeemB = await token.balanceOf(userAddressB);

      const redemptionAmountA = await vault.calculateTokenRedemption(depositAmount, userAddressA);
      const redemptionAmountB = await vault.calculateTokenRedemption(depositAmount, userAddressB);

      //Skip checks
      await toggleMaturityCheck(vault, false);
      await toggleWindowCheck(vault, false);

      await sdkA.redeem(vaultAddress, shares, userAddressA);
      await sdkB.redeem(vaultAddress, shares, userAddressB);

      const shareBalanceAfterRedeemA = await vault.balanceOf(userAddressA);
      const shareBalanceAfterRedeemB = await vault.balanceOf(userAddressB);

      const tokenBalanceAfterRedeemA = await token.balanceOf(userAddressA);
      const tokenBalanceAfterRedeemB = await token.balanceOf(userAddressB);

      expect(tokenBalanceBeforeRedeemA.add(redemptionAmountA).toString()).toEqual(tokenBalanceAfterRedeemA.toString());
      expect(tokenBalanceBeforeRedeemB.add(redemptionAmountB).toString()).toEqual(tokenBalanceAfterRedeemB.toString());

      expect(shareBalanceBeforeRedeemA.sub(shares).toString()).toEqual(shareBalanceAfterRedeemA.toString());
      expect(shareBalanceBeforeRedeemB.sub(shares).toString()).toEqual(shareBalanceAfterRedeemB.toString());
    });
  });
});
