// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { BigNumber, ethers } from 'ethers';

import { whitelist } from './utils/admin';
import { loadConfiguration } from './utils/config';
import { TRASH_ADDRESS, __mockMint, toggleWindowCheck } from './utils/contracts';
import { createFixedYieldVault } from './utils/ops';
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

test.describe('Multi user Interaction - Fixed', async () => {
  test.describe.configure({ mode: 'serial' });

  let vaultAddress: string;

  test('Deposit and redeem flow', async () => {
    const depositAmount = BigNumber.from('100000000');

    await test.step('Create Fixed Yield vault', async () => {
      await createFixedYieldVault(config, undefined, undefined, 200);
    });

    vaultAddress = await test.step('Get all vaults', async () => {
      const vaults = await alice.sdk.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const fixedVault = vaults.data.filter((vault: any) => vault.type === 'fixed_yield');
      fixedVault.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
      expect(fixedVault).toBeTruthy();

      return fixedVault[fixedVault.length - 1].address;
    });

    await test.step('Whitelist users', async () => {
      await whitelist(config, admin, alice.address, alice.id);
      await whitelist(config, admin, bob.address, bob.id);
    });

    await test.step('Empty custodian and user', async () => {
      const vault = await alice.sdk.getVaultInstance(vaultAddress);
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);
      const custodian = await vault.CUSTODIAN();
      const custodianBalance = await usdc.balanceOf(custodian);
      const aliceBalance = await usdc.balanceOf(alice.address);
      const bobBalance = await usdc.balanceOf(bob.address);
      await usdc.connect(testSigners.custodian.getDelegate()).transfer(TRASH_ADDRESS, custodianBalance);
      await usdc.connect(alice.testSigner.getDelegate()).transfer(TRASH_ADDRESS, aliceBalance);
      await usdc.connect(bob.testSigner.getDelegate()).transfer(TRASH_ADDRESS, bobBalance);
    });

    //MINT USDC for user
    await test.step('MINT USDC for user', async () => {
      const vault = await alice.sdk.getVaultInstance(vaultAddress);
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);
      const userABalance = await usdc.balanceOf(alice.address);
      const userBBalance = await usdc.balanceOf(bob.address);
      if (userABalance.lt(depositAmount)) {
        await __mockMint(alice.address, depositAmount, vault, alice.testSigner.getDelegate());
      }
      if (userBBalance.lt(depositAmount)) {
        await __mockMint(bob.address, depositAmount, vault, bob.testSigner.getDelegate());
      }
    });

    //Get approval for deposit
    await test.step('Get approval for deposit', async () => {
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);
      await usdc.connect(alice.testSigner.getDelegate()).approve(vaultAddress, depositAmount);
      await usdc.connect(bob.testSigner.getDelegate()).approve(vaultAddress, depositAmount);

      const approvalA = await usdc.allowance(alice.address, vaultAddress);
      const approvalB = await usdc.allowance(bob.address, vaultAddress);
      expect(approvalA.toString()).toEqual(depositAmount.toString());
      expect(approvalB.toString()).toEqual(depositAmount.toString());
    });

    //Deposit through SDK
    await test.step('Deposit through SDK', async () => {
      const vault = await alice.sdk.getVaultInstance(vaultAddress);
      const shareBalanceBeforeDepositA = await vault.balanceOf(alice.address);
      const shareBalanceBeforeDepositB = await vault.balanceOf(bob.address);

      const depositPreview = await vault.previewDeposit(depositAmount);

      await alice.sdk.deposit(vaultAddress, depositAmount, alice.address);
      await bob.sdk.deposit(vaultAddress, depositAmount, bob.address);

      const shareBalanceAfterDepositA = await vault.balanceOf(alice.address);
      const shareBalanceAfterDepositB = await vault.balanceOf(bob.address);

      expect(shareBalanceBeforeDepositA.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositA.toString());
      expect(shareBalanceBeforeDepositB.add(depositPreview).toString()).toEqual(shareBalanceAfterDepositB.toString());
    });

    // Redeem through SDK
    await test.step('Redeem through SDK', async () => {
      const vault = await alice.sdk.getVaultInstance(vaultAddress);
      const usdc = await alice.sdk.getAssetInstance(vaultAddress);

      const totalDeposited = await vault.totalAssetDeposited();
      const yeildAmount = totalDeposited.mul(10).div(100);

      const mintAmount = totalDeposited.add(yeildAmount);

      // Mature vault
      await __mockMint(vaultAddress, mintAmount, vault, alice.testSigner.getDelegate());

      const shares = depositAmount;
      const shareBalanceBeforeRedeemA = await vault.balanceOf(alice.address);
      const shareBalanceBeforeRedeemB = await vault.balanceOf(bob.address);

      const usdcBalanceBeofreRedeemA = await usdc.balanceOf(alice.address);
      const usdcBalanceBeofreRedeemB = await usdc.balanceOf(bob.address);

      await vault.connect(testSigners.operator.getDelegate()).mature();
      await toggleWindowCheck(admin, vault);

      const redeemPreviewA = await vault.previewRedeem(shares);

      await alice.sdk.redeem(vaultAddress, shares, alice.address);

      const redeemPreviewB = await vault.previewRedeem(shares);

      await bob.sdk.redeem(vaultAddress, shares, bob.address);

      const shareBalanceAfterRedeemA = await vault.balanceOf(alice.address);
      const shareBalanceAfterRedeemB = await vault.balanceOf(bob.address);

      const usdcBalanceAfterRedeemA = await usdc.balanceOf(alice.address);
      const usdcBalanceAfterRedeemB = await usdc.balanceOf(bob.address);

      expect(shareBalanceBeforeRedeemA.sub(shares).toString()).toEqual(shareBalanceAfterRedeemA.toString());
      expect(shareBalanceBeforeRedeemB.sub(shares).toString()).toEqual(shareBalanceAfterRedeemB.toString());

      expect(usdcBalanceBeofreRedeemA.add(redeemPreviewA).toString()).toEqual(usdcBalanceAfterRedeemA.toString());
      expect(usdcBalanceBeofreRedeemB.add(redeemPreviewB).toString()).toEqual(usdcBalanceAfterRedeemB.toString());
    });
  });
});
