// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { BigNumber, ethers } from 'ethers';

import { whitelist } from './utils/admin';
import { signerFor } from './utils/api';
import { loadConfiguration } from './utils/config';
import { TRASH_ADDRESS, __mockMint } from './utils/contracts';
import { distributeFixedYieldVault } from './utils/cron';
import { createFixedYieldVault } from './utils/ops';
import { TestSigners } from './utils/test-signer';
import { User, userFor } from './utils/user';
import { generateAddress, wait } from './utils/utils';

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

test.describe('Claim yield and principal - Fixed', async () => {
  test.describe.configure({ mode: 'serial' });

  let vaultAddress: string[];

  test('Claim funds from Vaults with shared Circle and Treasury addresses but different Reward address', async () => {
    const depositAmount = BigNumber.from('1000000000');

    let treasuryAddresses: string[];
    let activityRewardAddresses: string[];
    let treasuryPrivateKey: string[];
    let activityRewardPrivateKey: string[];

    await test.step('Create fixed yield vault', async () => {
      const { privateKey: treasuryPk, address: treasury } = generateAddress('treasury');
      const { privateKey: activityRewardPk, address: activityReward } = generateAddress('activity_reward');
      await createFixedYieldVault(config, treasury, activityReward, 200);

      const { privateKey: treasuryPk2, address: treasury2 } = generateAddress('treasury');
      const { privateKey: activityRewardPk2, address: activityReward2 } = generateAddress('activity_reward2');
      await createFixedYieldVault(config, treasury2, activityReward2, 200);

      treasuryAddresses = [treasury, treasury2];
      activityRewardAddresses = [activityReward, activityReward2];
      treasuryPrivateKey = [treasuryPk, treasuryPk2];
      activityRewardPrivateKey = [activityRewardPk, activityRewardPk2];
    });

    await test.step('Whitelist users', async () => {
      await whitelist(config, admin, alice.address, alice.id);
      await whitelist(config, admin, bob.address, bob.id);
    });

    vaultAddress = await test.step('Get vault and filter', async () => {
      const vaults = await alice.sdk.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const fixedYieldVaults = vaults.data.filter((vault: any) => vault.type === 'fixed_yield');

      //sort by created_at
      fixedYieldVaults.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
      expect(fixedYieldVaults).toBeTruthy();

      return [
        fixedYieldVaults[fixedYieldVaults.length - 1].address,
        fixedYieldVaults[fixedYieldVaults.length - 2].address,
      ];
    });

    await test.step('Empty custodian', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await alice.sdk.getVaultInstance(vaultAddress[i]);
        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        const custodianBalance = await usdc.balanceOf(custodian);
        if (custodianBalance.gt(0)) {
          await usdc.connect(testSigners.custodian.getDelegate()).transfer(TRASH_ADDRESS, custodianBalance);
        }
      }
    });

    await test.step('MINT USDC for user', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await alice.sdk.getVaultInstance(vaultAddress[i]);

        await __mockMint(alice.address, depositAmount, vault, alice.testSigner.getDelegate());
        await __mockMint(bob.address, depositAmount, vault, bob.testSigner.getDelegate());
      }
    });

    await test.step('Approve USDC', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);
        await usdc.connect(alice.testSigner.getDelegate()).approve(vaultAddress[i], depositAmount);
        await usdc.connect(bob.testSigner.getDelegate()).approve(vaultAddress[i], depositAmount);
      }
    });

    await test.step('Deposit to the vault', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        await alice.sdk.deposit(vaultAddress[i], depositAmount, alice.address);
        await bob.sdk.deposit(vaultAddress[i], depositAmount, bob.address);
      }
    });

    await test.step('Distribute yield', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await alice.sdk.getVaultInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        await __mockMint(custodian, BigNumber.from('1000000000'), vault, alice.testSigner.getDelegate());

        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);

        // Clean up treasury and activity reward balances
        const treasuryBalance = await usdc.balanceOf(treasuryAddresses[i]);
        const activityRewardBalance = await usdc.balanceOf(activityRewardAddresses[i]);

        const treasurySigner = signerFor(config, treasuryPrivateKey[i]);
        const activityRewardSigner = signerFor(config, activityRewardPrivateKey[i]);
        if (treasuryBalance.gt(0)) {
          await usdc.connect(treasurySigner).transfer(TRASH_ADDRESS, treasuryBalance);
        }

        if (activityRewardBalance.gt(0)) {
          await usdc.connect(activityRewardSigner).transfer(TRASH_ADDRESS, activityRewardBalance);
        }
      }

      await distributeFixedYieldVault(config);

      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);
        const treasuryBalanceAfterDistribution = await usdc.balanceOf(treasuryAddresses[i]);
        const activityRewardBalanceAfterDistribution = await usdc.balanceOf(activityRewardAddresses[i]);

        expect(treasuryBalanceAfterDistribution.toString()).toEqual(BigNumber.from('640000000').mul(2).toString());
        expect(activityRewardBalanceAfterDistribution.toString()).toEqual(BigNumber.from('160000000').toString());
      }
    });
  });

  test('Claim funds from Vaults with different Circle address but same Reward and Treasury addresses', async () => {
    const depositAmount = BigNumber.from('1000000000');

    let treasuryAddresses: string[];
    let activityRewardAddresses: string[];
    let treasuryPrivateKey: string[];
    let activityRewardPrivateKey: string[];

    await test.step('Create fixed yield vault', async () => {
      const { privateKey: treasuryPk, address: treasury } = generateAddress('treasury-test2');
      const { privateKey: activityRewardPk, address: activityReward } = generateAddress('activity_reward-test2');
      await createFixedYieldVault(config, treasury, activityReward, 200);

      const { privateKey: treasuryPk2, address: treasury2 } = generateAddress('treasury-test2');
      const { privateKey: activityRewardPk2, address: activityReward2 } = generateAddress('activity_reward-test2');

      await createFixedYieldVault(config, treasury2, activityReward2, 200);

      treasuryAddresses = [treasury, treasury2];
      activityRewardAddresses = [activityReward, activityReward2];
      treasuryPrivateKey = [treasuryPk, treasuryPk2];
      activityRewardPrivateKey = [activityRewardPk, activityRewardPk2];
    });

    vaultAddress = await test.step('Get vault and filter', async () => {
      const vaults = await alice.sdk.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const fixedYieldVaults = vaults.data.filter((vault: any) => vault.type === 'fixed_yield');

      //sort by created_at
      fixedYieldVaults.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
      expect(fixedYieldVaults).toBeTruthy();

      return [
        fixedYieldVaults[fixedYieldVaults.length - 1].address,
        fixedYieldVaults[fixedYieldVaults.length - 2].address,
      ];
    });

    await test.step('Empty custodian', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await alice.sdk.getVaultInstance(vaultAddress[i]);
        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        const custodianBalance = await usdc.balanceOf(custodian);
        if (custodianBalance.gt(0)) {
          await usdc.connect(testSigners.custodian.getDelegate()).transfer(TRASH_ADDRESS, custodianBalance);
        }
      }
    });

    await test.step('MINT USDC for user', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await alice.sdk.getVaultInstance(vaultAddress[i]);

        await __mockMint(alice.address, depositAmount, vault, alice.testSigner.getDelegate());
        await __mockMint(bob.address, depositAmount, vault, bob.testSigner.getDelegate());
      }
    });

    await test.step('Approve USDC', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);
        await usdc.connect(alice.testSigner.getDelegate()).approve(vaultAddress[i], depositAmount);
        await usdc.connect(bob.testSigner.getDelegate()).approve(vaultAddress[i], depositAmount);
      }
    });

    await test.step('Deposit to the vault', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        await alice.sdk.deposit(vaultAddress[i], depositAmount, alice.address);
        await bob.sdk.deposit(vaultAddress[i], depositAmount, bob.address);
      }
    });

    await test.step('Distribute yield', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await alice.sdk.getVaultInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        await __mockMint(custodian, BigNumber.from('1000000000'), vault, alice.testSigner.getDelegate());

        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);

        //Clean up treasury and activity reward balances
        const treasuryBalance = await usdc.balanceOf(treasuryAddresses[i]);
        const activityRewardBalance = await usdc.balanceOf(activityRewardAddresses[i]);

        const treasurySigner = signerFor(config, treasuryPrivateKey[i]);
        const activityRewardSigner = signerFor(config, activityRewardPrivateKey[i]);
        if (treasuryBalance.gt(0)) {
          await usdc.connect(treasurySigner).transfer(TRASH_ADDRESS, treasuryBalance);
        }

        await wait(1000);
        if (activityRewardBalance.gt(0)) {
          await usdc.connect(activityRewardSigner).transfer(TRASH_ADDRESS, activityRewardBalance);
        }
        await wait(1000);
      }

      await distributeFixedYieldVault(config);

      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await alice.sdk.getAssetInstance(vaultAddress[i]);
        const treasuryBalanceAfterDistribution = await usdc.balanceOf(treasuryAddresses[i]);
        const activityRewardBalanceAfterDistribution = await usdc.balanceOf(activityRewardAddresses[i]);

        expect(treasuryBalanceAfterDistribution.toString()).toEqual(BigNumber.from('640000000').mul(2).toString());
        expect(activityRewardBalanceAfterDistribution.toString()).toEqual(
          BigNumber.from('160000000').mul(2).toString(),
        );
      }
    });
  });
});
