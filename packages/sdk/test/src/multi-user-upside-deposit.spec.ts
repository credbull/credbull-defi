// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { triggerAsyncId } from 'async_hooks';
import { BigNumber, Signer, ethers } from 'ethers';

import { whitelist } from './utils/admin';
import { loadConfiguration } from './utils/config';
import { TRASH_ADDRESS, __mockMint, __mockMintToken, toggleWindowCheck } from './utils/contracts';
import { createFixedYieldWithUpsideVault } from './utils/ops';
import { TestSigners } from './utils/test-signer';
import { User, userFor } from './utils/user';

let config: any;
let testSigners: TestSigners;
let admin: User;
let alice: User;
let bob: User;

// NOTE (JL,2024-06-13): By experimentation, this is invoked before EVERY top-level `test`.
test.beforeAll('Setup', async () => {
  config = loadConfiguration();

  testSigners = new TestSigners(new ethers.providers.JsonRpcProvider(config.services.ethers.url));

  admin = await userFor(config, config.users.admin.email_address, config.secret.ADMIN_PASSWORD, testSigners.admin);
  alice = await userFor(config, config.users.alice.email_address, config.secret.ALICE_PASSWORD, testSigners.alice);
  bob = await userFor(config, config.users.bob.email_address, config.secret.BOB_PASSWORD, testSigners.bob);

  await alice.sdk.linkWallet();
  await bob.sdk.linkWallet();
});

test.describe.skip('Multi user Interaction - Upside', async () => {
  test.describe.configure({ mode: 'serial' });

  let vaultAddress: string;

  test('Deposit and redeem flow', async () => {
    const depositAmount = BigNumber.from('100000000');

    await test.step('Create upside vault', async () => {
      await createFixedYieldWithUpsideVault(config, undefined, undefined, undefined, 200);
    });

    await test.step('Get all vaults and filter upside', async () => {
      const vaults = await alice.sdk.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const upsideVault = vaults.data.filter((vault: any) => vault.type === 'fixed_yield_upside');
      upsideVault.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

      expect(upsideVault).toBeTruthy();

      vaultAddress = upsideVault[upsideVault.length - 1].address;
    });

    await test.step('Whitelist users', async () => {
      await whitelist(config, admin, alice.address, alice.id);
      await whitelist(config, admin, bob.address, bob.id);
    });

    await test.step('Empty custodian', async () => {
      const vault = await alice.sdk.getVaultInstance(vaultAddress);
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);
      const custodian = await vault.CUSTODIAN();
      const custodianBalance = await usdc.balanceOf(custodian);
      await usdc.connect(testSigners.custodian.getDelegate()).transfer(TRASH_ADDRESS, custodianBalance);
    });

    //MINT USDC for user
    const collateralRequired = await test.step('MINT USDC and CBL token for user', async () => {
      const vault = await alice.sdk.getUpsideVaultInstance(vaultAddress);
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);

      const collateralRequired = await vault.getCollateralAmount(depositAmount);

      const userABalance = await usdc.balanceOf(alice.address);
      const userBBalance = await usdc.balanceOf(bob.address);

      if (userABalance.lt(depositAmount))
        await __mockMint(alice.address, depositAmount, vault, alice.testSigner.getDelegate());
      if (userBBalance.lt(depositAmount))
        await __mockMint(bob.address, depositAmount, vault, bob.testSigner.getDelegate());

      await __mockMintToken(alice.address, collateralRequired, vault, alice.testSigner.getDelegate());
      await __mockMintToken(bob.address, collateralRequired, vault, bob.testSigner.getDelegate());

      return collateralRequired;
    });

    //Get approval for deposit
    await test.step('Get approval for deposit', async () => {
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);
      await usdc.connect(alice.testSigner.getDelegate()).approve(vaultAddress, depositAmount);
      await usdc.connect(bob.testSigner.getDelegate()).approve(vaultAddress, depositAmount);

      const token = await alice.sdk.getTokenInstance(vaultAddress);
      await token.connect(alice.testSigner.getDelegate()).approve(vaultAddress, collateralRequired);
      await token.connect(bob.testSigner.getDelegate()).approve(vaultAddress, collateralRequired);

      const tokenApprovalA = await token.allowance(alice.address, vaultAddress);
      const tokenApprovalB = await token.allowance(bob.address, vaultAddress);

      expect(tokenApprovalA.toString()).toEqual(collateralRequired.toString());
      expect(tokenApprovalB.toString()).toEqual(collateralRequired.toString());

      const approvalA = await usdc.allowance(alice.address, vaultAddress);
      const approvalB = await usdc.allowance(bob.address, vaultAddress);
      expect(approvalA.toString()).toEqual(depositAmount.toString());
      expect(approvalB.toString()).toEqual(depositAmount.toString());
    });

    //Deposit through SDK
    await test.step('Deposit through SDK', async () => {
      const vault = await alice.sdk.getUpsideVaultInstance(vaultAddress);
      const token = await alice.sdk.getTokenInstance(vaultAddress);

      const shareBalanceBeforeDepositA = await vault.balanceOf(alice.address);
      const shareBalanceBeforeDepositB = await vault.balanceOf(bob.address);

      const vaultTokenBalanceBeforeDeposit = await token.balanceOf(vaultAddress);

      await alice.sdk.deposit(vaultAddress, depositAmount, alice.address);
      await bob.sdk.deposit(vaultAddress, depositAmount, bob.address);

      const depositPreview = await vault.previewDeposit(depositAmount);

      const shareBalanceAfterDepositA = await vault.balanceOf(alice.address);
      const shareBalanceAfterDepositB = await vault.balanceOf(bob.address);

      const vaultTokenBalanceAfterDeposit = await token.balanceOf(vaultAddress);

      expect(vaultTokenBalanceBeforeDeposit.add(collateralRequired.mul(2)).toString()).toEqual(
        vaultTokenBalanceAfterDeposit.toString(),
      );

      expect(shareBalanceBeforeDepositA.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositA.toString());
      expect(shareBalanceBeforeDepositB.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositB.toString());
    });

    //Redeem through SDK
    await test.step('Redeem through SDK', async () => {
      const vault = await alice.sdk.getUpsideVaultInstance(vaultAddress);
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);
      const token = await alice.sdk.getTokenInstance(vaultAddress);
      const shares = depositAmount;

      const totalDeposited = await vault.totalAssetDeposited();
      const yeildAmount = totalDeposited.mul(10).div(100);
      const upsideYieldAmount = (await token.balanceOf(vaultAddress)).mul(10).div(100).div(1e12);
      const mintAmount = totalDeposited.add(yeildAmount).add(upsideYieldAmount);

      //Mature vault
      await __mockMint(vaultAddress, mintAmount, vault, alice.testSigner.getDelegate());

      const shareBalanceBeforeRedeemA = await vault.balanceOf(alice.address);
      const shareBalanceBeforeRedeemB = await vault.balanceOf(bob.address);

      const tokenBalanceBeforeRedeemA = await token.balanceOf(alice.address);
      const tokenBalanceBeforeRedeemB = await token.balanceOf(bob.address);

      const usdcBalanceBeforeRedeemA = await usdc.balanceOf(alice.address);
      const usdcBalanceBeforeRedeemB = await usdc.balanceOf(bob.address);

      const previewDeposit = await vault.previewDeposit(depositAmount);
      const redemptionAmountA = await vault.calculateTokenRedemption(previewDeposit, alice.address);
      const redemptionAmountB = await vault.calculateTokenRedemption(previewDeposit, bob.address);

      //Skip checks
      await vault.connect(testSigners.operator.getDelegate()).mature();
      await toggleWindowCheck(admin, vault);

      const redeemPreviewA = await vault.previewRedeem(shares);
      await alice.sdk.redeem(vaultAddress, shares, alice.address);

      const redeemPreviewB = await vault.previewRedeem(shares);
      await bob.sdk.redeem(vaultAddress, shares, bob.address);

      const shareBalanceAfterRedeemA = await vault.balanceOf(alice.address);
      const shareBalanceAfterRedeemB = await vault.balanceOf(bob.address);

      const tokenBalanceAfterRedeemA = await token.balanceOf(alice.address);
      const tokenBalanceAfterRedeemB = await token.balanceOf(bob.address);

      const usdcBalanceAfterRedeemA = await usdc.balanceOf(alice.address);
      const usdcBalanceAfterRedeemB = await usdc.balanceOf(bob.address);

      expect(tokenBalanceBeforeRedeemA.add(redemptionAmountA).toString()).toEqual(tokenBalanceAfterRedeemA.toString());
      expect(tokenBalanceBeforeRedeemB.add(redemptionAmountB).toString()).toEqual(tokenBalanceAfterRedeemB.toString());

      expect(shareBalanceBeforeRedeemA.sub(previewDeposit).toString()).toEqual(shareBalanceAfterRedeemA.toString());
      expect(shareBalanceBeforeRedeemB.sub(previewDeposit).toString()).toEqual(shareBalanceAfterRedeemB.toString());

      expect(usdcBalanceBeforeRedeemA.add(redeemPreviewA).toString()).toEqual(usdcBalanceAfterRedeemA.toString());
      expect(usdcBalanceBeforeRedeemB.add(redeemPreviewB).toString()).toEqual(usdcBalanceAfterRedeemB.toString());
    });
  });
});
