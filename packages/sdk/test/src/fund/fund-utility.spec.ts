import { test } from '@playwright/test';
import { Wallet, ethers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';

let provider: ethers.providers.JsonRpcProvider;
let config: Config;

let userSigner: Wallet;

const manualValueOracleAddress: string = '0x6748B0f4Cd17d1dE0CF718c747D6C0897B2922fb'; // Dec deploy

test.beforeAll(async () => {
  config = loadConfiguration();

  provider = new ethers.providers.JsonRpcProvider(config.services.ethers.url);
  userSigner = new ethers.Wallet(config.secret.DEPLOYER_PRIVATE_KEY, provider);
});

test.describe.skip('Test Fund', () => {
  test('Test Manual value oracle read functions', async () => {
    const contract = new ethers.Contract(manualValueOracleAddress, ABI_MANUAL_VALUE_ORACLE, provider);
    const connectedContract = contract.connect(userSigner);
    console.log('Updater: ', (await connectedContract.getUpdater()).toString());
    console.log('Value: ', (await connectedContract.getValue()).toString());
  });

  test('Test Manual value oracle update value', async () => {
    const contract = new ethers.Contract(manualValueOracleAddress, ABI_MANUAL_VALUE_ORACLE, provider);
    const connectedContract = contract.connect(userSigner);

    const prevValue = (await connectedContract.getValue()).toNumber();
    console.log('Prev Value: ', prevValue);

    const newValue = 500000000; // prevValue + 1;

    const estimatedGas = await connectedContract.estimateGas.updateValue(newValue);
    console.log('Estimated Gas:', estimatedGas.toString());

    // ======================= simulate =======================
    const feeData = await provider.getFeeData();
    const gasTipCap = ethers.BigNumber.from('25000000000'); // 25 Gwei
    const maxFeePerGas = feeData.maxFeePerGas; // Ensure this covers base + priority fee

    try {
      await connectedContract.callStatic.updateValue(newValue, {
        gasLimit: estimatedGas,
      });

      console.log('Transaction simulation successful! The transaction would succeed.');
    } catch (error) {
      console.error('Transaction simulation failed:', error.message);
    }

    // ======================= execute =======================

    try {
      const tx = await connectedContract.updateValue(newValue, {
        maxPriorityFeePerGas: gasTipCap,
        maxFeePerGas,
        gasLimit: estimatedGas,
      });
      const receipt = await tx.wait();
      console.log('Transaction successful:', receipt.transactionHash);
    } catch (error) {
      console.error('Transaction error:', error.error?.message || error.message);
      throw error;
    }

    console.log('New Value: ', (await connectedContract.getValue()).toString());
  });
});

const ABI_MANUAL_VALUE_ORACLE = [
  {
    inputs: [],
    name: 'getValue',
    outputs: [
      {
        internalType: 'int256',
        name: 'value_',
        type: 'int256',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [],
    name: 'getUpdater',
    outputs: [
      {
        internalType: 'address',
        name: 'updater_',
        type: 'address',
      },
    ],
    stateMutability: 'view',
    type: 'function',
  },
  {
    inputs: [
      {
        internalType: 'int192',
        name: '_nextValue',
        type: 'int192',
      },
    ],
    name: 'updateValue',
    outputs: [],
    stateMutability: 'nonpayable',
    type: 'function',
  },
];
