// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { config } from 'dotenv';
import { BigNumber, Signer } from 'ethers';

import { CredbullSDK } from '../index';
import { signer } from '../mock/utils/helpers';

import {
  __mockMint,
  __mockMintToken,
  createUpsideVaultVault,
  login,
  toggleWindowCheck,
  whitelist,
} from './utils/admin-ops';

config();

let walletSignerA: Signer | undefined = undefined;
let walletSignerB: Signer | undefined = undefined;
let operatorSigner: Signer | undefined = undefined;
let custodianSigner: Signer | undefined = undefined;

let sdkA: CredbullSDK;
let sdkB: CredbullSDK;

let userAddressA: string;
let userAddressB: string;

let userAId: string;
let userBId: string;

let vaultAddress: string;

test.beforeAll(async () => {
  const { access_token: userAToken, user_id: _userAId } = await login(
    process.env.USER_A_EMAIL || '',
    process.env.USER_A_PASSWORD || '',
  );
  const { access_token: userBToken, user_id: _userBId } = await login(
    process.env.USER_B_EMAIL || '',
    process.env.USER_B_PASSWORD || '',
  );

  walletSignerA = signer(process.env.USER_A_PRIVATE_KEY || '0x');
  walletSignerB = signer(process.env.USER_B_PRIVATE_KEY || '0x');
  operatorSigner = signer(process.env.OPERATOR_PRIVATE_KEY || '0x');
  custodianSigner = signer(process.env.CUSTODIAN_PRIVATE_KEY || '0x');

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

test.describe('Multi user Interaction - Upside', async () => {
  test('Deposit and redeem flow', async () => {
    const depositAmount = BigNumber.from('100000000');

    await test.step('Create upside vault', async () => {
      await createUpsideVaultVault();
    });

    await test.step('Get all vaults and filter upside', async () => {
      const vaults = await sdkA.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const upsideVault = vaults.data.filter((vault: any) => vault.type === 'fixed_yield_upside');
      upsideVault.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
      
      expect(upsideVault).toBeTruthy();

      vaultAddress = upsideVault[upsideVault.length - 1].address;
    });

    await test.step('Whitelist users', async () => {
      await whitelist(userAddressA, userAId);
      await whitelist(userAddressB, userBId);
    });

    await test.step('Empty custodian', async() => {
      const vault = await sdkA.getVaultInstance(vaultAddress);
      const usdc = await sdkA.getAssetInstance(vaultAddress);
      const custodian = await vault.CUSTODIAN();
      const custodianBalance = await usdc.balanceOf(custodian);
      console.log('custodian balance', custodianBalance.toString());
      console.log('signer address', await custodianSigner?.getAddress());
      usdc.connect(custodianSigner as Signer).transfer("0xcabE80b332Aa9d900f5e32DF51cb0Bc5b276c556", custodianBalance);
      console.log('custodian address', custodian);
      console.log('custodian balance', (await usdc.balanceOf(custodian)).toString());
    });

    //MINT USDC for user
    const collateralRequired = await test.step('MINT USDC and CBL token for user', async () => {
      const vault = await sdkA.getUpsideVaultInstance(vaultAddress);
      const usdc = await sdkA.getAssetInstance(vaultAddress);

      const collateralRequired = await vault.getCollateralAmount(depositAmount);

      const userABalance = await usdc.balanceOf(await (walletSignerA as Signer).getAddress());
      const userBBalance = await usdc.balanceOf(await (walletSignerB as Signer).getAddress());

      if (userABalance.lt(depositAmount))
        await __mockMint(await (walletSignerA as Signer).getAddress(), depositAmount, vault, walletSignerA as Signer);
      if (userBBalance.lt(depositAmount))
        await __mockMint(await (walletSignerB as Signer).getAddress(), depositAmount, vault, walletSignerB as Signer);

      await __mockMintToken(
        await (walletSignerA as Signer).getAddress(),
        collateralRequired,
        vault,
        walletSignerA as Signer,
      );
      await __mockMintToken(
        await (walletSignerB as Signer).getAddress(),
        collateralRequired,
        vault,
        walletSignerB as Signer,
      );

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

      const depositPreview = await vault.previewDeposit(depositAmount);

      const shareBalanceAfterDepositA = await vault.balanceOf(userAddressA);
      const shareBalanceAfterDepositB = await vault.balanceOf(userAddressB);

      const vaultTokenBalanceAfterDeposit = await token.balanceOf(vaultAddress);

      expect(vaultTokenBalanceBeforeDeposit.add(collateralRequired.mul(2)).toString()).toEqual(
        vaultTokenBalanceAfterDeposit.toString(),
      );

      expect(shareBalanceBeforeDepositA.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositA.toString());
      expect(shareBalanceBeforeDepositB.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositB.toString());
    });

    //Redeem through SDK
    await test.step('Redeem through SDK', async () => {
      const vault = await sdkA.getUpsideVaultInstance(vaultAddress);
      // const usdc = await sdkA.getAssetInstance(vaultAddress);
      const token = await sdkA.getTokenInstance(vaultAddress);

      const totalDeposited = await vault.totalAssetDeposited();

      const yeildAmount = totalDeposited.mul(10).div(100);

      const upsideYieldAmount = (await token.balanceOf(vaultAddress)).mul(10).div(100).div(1e12);

      const mintAmount = totalDeposited.add(yeildAmount).add(upsideYieldAmount);

      //Mature vault
      await __mockMint(vaultAddress, mintAmount, vault, walletSignerA as Signer);

      const shareBalanceBeforeRedeemA = await vault.balanceOf(userAddressA);
      const shareBalanceBeforeRedeemB = await vault.balanceOf(userAddressB);

      const tokenBalanceBeforeRedeemA = await token.balanceOf(userAddressA);
      const tokenBalanceBeforeRedeemB = await token.balanceOf(userAddressB);

      // const usdcBalanceBeforeRedeemA = await usdc.balanceOf(userAddressA);
      // const usdcBalanceBeforeRedeemB = await usdc.balanceOf(userAddressB);

      const previewDeposit = await vault.previewDeposit(depositAmount);
      const redemptionAmountA = await vault.calculateTokenRedemption(previewDeposit, userAddressA);
      const redemptionAmountB = await vault.calculateTokenRedemption(previewDeposit, userAddressB);

      //Skip checks
      await vault.connect(operatorSigner as Signer).mature();
      await toggleWindowCheck(vault, false);

      //const previewRedeem = await vault.previewRedeem(previewDeposit);

      await sdkA.redeem(vaultAddress, previewDeposit, userAddressA);
      await sdkB.redeem(vaultAddress, previewDeposit, userAddressB);

      const shareBalanceAfterRedeemA = await vault.balanceOf(userAddressA);
      const shareBalanceAfterRedeemB = await vault.balanceOf(userAddressB);

      const tokenBalanceAfterRedeemA = await token.balanceOf(userAddressA);
      const tokenBalanceAfterRedeemB = await token.balanceOf(userAddressB);

      expect(tokenBalanceBeforeRedeemA.add(redemptionAmountA).toString()).toEqual(tokenBalanceAfterRedeemA.toString());
      expect(tokenBalanceBeforeRedeemB.add(redemptionAmountB).toString()).toEqual(tokenBalanceAfterRedeemB.toString());

      expect(shareBalanceBeforeRedeemA.sub(previewDeposit).toString()).toEqual(shareBalanceAfterRedeemA.toString());
      expect(shareBalanceBeforeRedeemB.sub(previewDeposit).toString()).toEqual(shareBalanceAfterRedeemB.toString());
    });
  });
});
