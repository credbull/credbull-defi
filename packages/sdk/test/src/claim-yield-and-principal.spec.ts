// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { config } from 'dotenv';
import { BigNumber, Signer } from 'ethers';

import { CredbullSDK } from '../../src/index';

import { signer } from './mock/utils/helpers';
import {
  TRASH_ADDRESS,
  __mockMint,
  createFixedYieldVault,
  distributeFixedYieldVault,
  generateAddress,
  login,
  sleep,
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

let vaultAddress: string[];

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

  sdkA = new CredbullSDK(process.env.BASE_URL || '', userAToken, walletSignerA as Signer);
  sdkB = new CredbullSDK(process.env.BASE_URL || '', userBToken, walletSignerB as Signer);

  userAddressA = await (walletSignerA as Signer).getAddress();
  userAddressB = await (walletSignerB as Signer).getAddress();

  userAId = _userAId;
  userBId = _userBId;

  //link wallet
  await sdkA.linkWallet();
  await sdkB.linkWallet();
});

test.describe('Claim yield and principal - Fixed', async () => {
  test('Claim funds from Vaults with shared Circle and Treasury addresses but different Reward address', async () => {
    const depositAmount = BigNumber.from('1000000000');

    let treasuryAddresses: string[];
    let activityRewardAddresses: string[];
    let treasuryPrivateKey: string[];
    let activityRewardPrivateKey: string[];

    await test.step('Create fixed yield vault', async () => {
      const { pkey: treasuryPkey, address: treasury } = generateAddress('treasury');
      const { pkey: activityRewardPkey, address: activityReward } = generateAddress('activity_reward');
      await createFixedYieldVault({
        ADDRESSES_TREASURY: treasury,
        ADDRESSES_ACTIVITY_REWARD: activityReward,
        COLLATERAL_PERCENTAGE: 200,
      });

      const { pkey: treasuryPkey2, address: treasury2 } = generateAddress('treasury');
      const { pkey: activityRewardPkey2, address: activityReward2 } = generateAddress('activity_reward2');
      await createFixedYieldVault({
        ADDRESSES_TREASURY: treasury2,
        ADDRESSES_ACTIVITY_REWARD: activityReward2,
        COLLATERAL_PERCENTAGE: 200,
      });

      treasuryAddresses = [treasury, treasury2];
      activityRewardAddresses = [activityReward, activityReward2];
      treasuryPrivateKey = [treasuryPkey, treasuryPkey2];
      activityRewardPrivateKey = [activityRewardPkey, activityRewardPkey2];
    });

    await test.step('Whitelist users', async () => {
      await whitelist(userAddressA, userAId);
      await whitelist(userAddressB, userBId);
    });

    vaultAddress = await test.step('Get vault and filter', async () => {
      try {
        await sdkA.getAllVaults();
      } catch (e) {}
      const vaults = await sdkA.getAllVaults();
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
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        const custodianBalance = await usdc.balanceOf(custodian);
        if (custodianBalance.gt(0)) {
          await usdc.connect(custodianSigner as Signer).transfer(TRASH_ADDRESS, custodianBalance);
        }
      }
    });

    await test.step('MINT USDC for user', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);

        await __mockMint(userAddressA, depositAmount, vault, walletSignerA as Signer);
        await __mockMint(userAddressB, depositAmount, vault, walletSignerB as Signer);
      }
    });

    await test.step('Approve USDC', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
        await usdc.connect(walletSignerA as Signer).approve(vaultAddress[i], depositAmount);
        await usdc.connect(walletSignerB as Signer).approve(vaultAddress[i], depositAmount);
      }
    });

    await test.step('Deposit to the vault', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        await sdkA.deposit(vaultAddress[i], depositAmount, userAddressA);
        await sdkB.deposit(vaultAddress[i], depositAmount, userAddressB);
      }
    });

    await test.step('Distribute yield', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        await __mockMint(custodian, BigNumber.from('1000000000'), vault, walletSignerA as Signer);

        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);

        //Clean up treasury and activity reward balances
        const treasuryBalance = await usdc.balanceOf(treasuryAddresses[i]);
        const activityRewardBalance = await usdc.balanceOf(activityRewardAddresses[i]);

        const treasurySigner = signer(treasuryPrivateKey[i]);
        const activityRewardSigner = signer(activityRewardPrivateKey[i]);
        if (treasuryBalance.gt(0)) {
          await usdc.connect(treasurySigner).transfer(TRASH_ADDRESS, treasuryBalance);
        }

        if (activityRewardBalance.gt(0)) {
          await usdc.connect(activityRewardSigner).transfer(TRASH_ADDRESS, activityRewardBalance);
        }
      }

      await distributeFixedYieldVault();

      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
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
      const { pkey: treasuryPkey, address: treasury } = generateAddress('treasury-test2');
      const { pkey: activityRewardPkey, address: activityReward } = generateAddress('activity_reward-test2');
      await createFixedYieldVault({
        ADDRESSES_TREASURY: treasury,
        ADDRESSES_ACTIVITY_REWARD: activityReward,
        COLLATERAL_PERCENTAGE: 200,
      });

      const { pkey: treasuryPkey2, address: treasury2 } = generateAddress('treasury-test2');
      const { pkey: activityRewardPkey2, address: activityReward2 } = generateAddress('activity_reward-test2');

      await createFixedYieldVault({
        ADDRESSES_TREASURY: treasury2,
        ADDRESSES_ACTIVITY_REWARD: activityReward2,
        COLLATERAL_PERCENTAGE: 200,
      });

      treasuryAddresses = [treasury, treasury2];
      activityRewardAddresses = [activityReward, activityReward2];
      treasuryPrivateKey = [treasuryPkey, treasuryPkey2];
      activityRewardPrivateKey = [activityRewardPkey, activityRewardPkey2];
    });

    vaultAddress = await test.step('Get vault and filter', async () => {
      try {
        await sdkA.getAllVaults();
      } catch (e) {}
      const vaults = await sdkA.getAllVaults();
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
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        const custodianBalance = await usdc.balanceOf(custodian);
        if (custodianBalance.gt(0)) {
          await usdc.connect(custodianSigner as Signer).transfer(TRASH_ADDRESS, custodianBalance);
        }
      }
    });

    await test.step('MINT USDC for user', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);

        await __mockMint(userAddressA, depositAmount, vault, walletSignerA as Signer);
        await __mockMint(userAddressB, depositAmount, vault, walletSignerB as Signer);
      }
    });

    await test.step('Approve USDC', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
        await usdc.connect(walletSignerA as Signer).approve(vaultAddress[i], depositAmount);
        await usdc.connect(walletSignerB as Signer).approve(vaultAddress[i], depositAmount);
      }
    });

    await test.step('Deposit to the vault', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        await sdkA.deposit(vaultAddress[i], depositAmount, userAddressA);
        await sdkB.deposit(vaultAddress[i], depositAmount, userAddressB);
      }
    });

    await test.step('Distribute yield', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        await __mockMint(custodian, BigNumber.from('1000000000'), vault, walletSignerA as Signer);

        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);

        //Clean up treasury and activity reward balances
        const treasuryBalance = await usdc.balanceOf(treasuryAddresses[i]);
        const activityRewardBalance = await usdc.balanceOf(activityRewardAddresses[i]);

        const treasurySigner = signer(treasuryPrivateKey[i]);
        const activityRewardSigner = signer(activityRewardPrivateKey[i]);
        if (treasuryBalance.gt(0)) {
          await usdc.connect(treasurySigner).transfer(TRASH_ADDRESS, treasuryBalance);
        }

        await sleep(1000);
        if (activityRewardBalance.gt(0)) {
          await usdc.connect(activityRewardSigner).transfer(TRASH_ADDRESS, activityRewardBalance);
        }
        await sleep(1000);
      }

      await distributeFixedYieldVault();

      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
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
