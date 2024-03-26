// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { config } from 'dotenv';
import { BigNumber, Signer } from 'ethers';

import { CredbullSDK } from '../index';
import { signer } from '../mock/utils/helpers';

import { __mockMint, createFixedYieldVault, login, toggleWindowCheck, whitelist } from './utils/admin-ops';

config();

let walletSignerA: Signer | undefined = undefined;
let walletSignerB: Signer | undefined = undefined;
let operatorSigner: Signer | undefined = undefined;

let sdkA: CredbullSDK;
let sdkB: CredbullSDK;

let userAddressA: string;
let userAddressB: string;

let userAId: string;
let userBId: string;

let vaultAddress: string;

test.beforeAll(async () => {
  const { access_token: userAToken, user_id: _userAId } = await login(process.env.USER_A_EMAIL || '', process.env.USER_A_PASSWORD || '');
  const { access_token: userBToken, user_id: _userBId } = await login(process.env.USER_B_EMAIL || '', process.env.USER_B_PASSWORD || '');

  walletSignerA = signer(process.env.USER_A_PRIVATE_KEY || '0x');
  walletSignerB = signer(process.env.USER_B_PRIVATE_KEY || '0x');
  operatorSigner = signer(process.env.OPERATOR_PRIVATE_KEY || '0x');

  sdkA = new CredbullSDK(userAToken, walletSignerA as Signer);
  sdkB = new CredbullSDK(userBToken, walletSignerB as Signer);

  userAddressA = await (walletSignerA as Signer).getAddress();
  userAddressB = await (walletSignerB as Signer).getAddress();

  userAId = _userAId;
  userBId = _userBId;

  //link wallet
  await sdkA.linkWallet();
  await sdkB.linkWallet();

});

test.describe('Multi user Interaction - Fixed', async () => {
  test('Deposit and redeem flow', async () => {
    const depositAmount = BigNumber.from('100000000');

    await test.step('Create upside vault', async() => {
      await createFixedYieldVault();
    })

    vaultAddress = await test.step('Get all vaults', async () => {
      const vaults = await sdkA.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const fixedVault = vaults.data.find((vault: any) => vault.type === 'fixed_yield');
      expect(fixedVault).toBeTruthy();

      return fixedVault.address;
    });

    await test.step("Whitelist users", async() => {
      await whitelist(userAddressA, userAId);
      await whitelist(userAddressB, userBId);
    });

    //MINT USDC for user
    await test.step('MINT USDC for user', async () => {
      const vault = await sdkA.getVaultInstance(vaultAddress);
      const usdc = await sdkA.getAssetInstance(vaultAddress);
      const userABalance = await usdc.balanceOf(await (walletSignerA as Signer).getAddress());
      const userBBalance = await usdc.balanceOf(await (walletSignerB as Signer).getAddress());
      if(userABalance.lt(depositAmount))
        await __mockMint(await (walletSignerA as Signer).getAddress(), depositAmount, vault, walletSignerA as Signer);
      if(userBBalance.lt(depositAmount))
        await __mockMint(await (walletSignerB as Signer).getAddress(), depositAmount, vault, walletSignerB as Signer);
    });

    //Get approval for deposit
    await test.step('Get approval for deposit', async () => {
      const usdc = await sdkA.getAssetInstance(vaultAddress);
      await usdc.connect(walletSignerA as Signer).approve(vaultAddress, depositAmount);
      await usdc.connect(walletSignerB as Signer).approve(vaultAddress, depositAmount);

      const approvalA = await usdc.allowance(await (walletSignerA as Signer).getAddress(), vaultAddress);
      const approvalB = await usdc.allowance(await (walletSignerB as Signer).getAddress(), vaultAddress);
      expect(approvalA.toString()).toEqual(depositAmount.toString());
      expect(approvalB.toString()).toEqual(depositAmount.toString());
    });

    //Deposit through SDK
    await test.step('Deposit through SDK', async () => {
      const vault = await sdkA.getVaultInstance(vaultAddress);
      const shareBalanceBeforeDepositA = await vault.balanceOf(userAddressA);
      const shareBalanceBeforeDepositB = await vault.balanceOf(userAddressB);

      const depositPreview = await vault.previewDeposit(depositAmount);

      await sdkA.deposit(vaultAddress, depositAmount, userAddressA);
      await sdkB.deposit(vaultAddress, depositAmount, userAddressB);

      const shareBalanceAfterDepositA = await vault.balanceOf(userAddressA);
      const shareBalanceAfterDepositB = await vault.balanceOf(userAddressB);

      expect(shareBalanceBeforeDepositA.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositA.toString());
      expect(shareBalanceBeforeDepositB.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositB.toString());
    });

    //Redeem through SDK
    await test.step('Redeem through SDK', async () => {
      const vault = await sdkA.getVaultInstance(vaultAddress);
      const usdc = await sdkA.getAssetInstance(vaultAddress);

      const totalDeposited = await vault.totalAssetDeposited();
      const yeildAmount = (totalDeposited.mul(10)).div(100);

      const mintAmount = totalDeposited.add(yeildAmount);

      //Mature vault
      await __mockMint(vaultAddress, mintAmount, vault, walletSignerA as Signer);

      const shares = depositAmount;
      const shareBalanceBeforeRedeemA = await vault.balanceOf(userAddressA);
      const shareBalanceBeforeRedeemB = await vault.balanceOf(userAddressB);

      const usdcBalanceBeofreRedeemA = await usdc.balanceOf(userAddressA);
      const usdcBalanceBeofreRedeemB = await usdc.balanceOf(userAddressB);

      //await vault.connect(operatorSigner as Signer).mature();
      await vault.connect(operatorSigner as Signer).mature();
      await toggleWindowCheck(vault, false);

      const previewDeposit = await vault.previewDeposit(depositAmount);

      await sdkA.redeem(vaultAddress, previewDeposit, userAddressA);
      await sdkB.redeem(vaultAddress, previewDeposit, userAddressB);

      const redeemPreview = await vault.previewRedeem(previewDeposit);

      const shareBalanceAfterRedeemA = await vault.balanceOf(userAddressA);
      const shareBalanceAfterRedeemB = await vault.balanceOf(userAddressB);

      const usdcBalanceAfterRedeemA = await usdc.balanceOf(userAddressA);
      const usdcBalanceAfterRedeemB = await usdc.balanceOf(userAddressB);

      expect(shareBalanceBeforeRedeemA.sub(previewDeposit).toString()).toEqual(shareBalanceAfterRedeemA.toString());
      expect(shareBalanceBeforeRedeemB.sub(previewDeposit).toString()).toEqual(shareBalanceAfterRedeemB.toString());


      // expect(usdcBalanceBeofreRedeemA.add(depositAmount).toString()).toEqual(usdcBalanceAfterRedeemA.toString());
      // expect(usdcBalanceBeofreRedeemB.add(redeemPreview).toString()).toEqual(usdcBalanceAfterRedeemB.toString());
    });
  });
});
