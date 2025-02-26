import { test } from '@playwright/test';
import { Wallet, ethers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';

let provider: ethers.providers.JsonRpcProvider;
let config: Config;

let userSigner: Wallet;

const fundValueCalculatorAddress: string = '0xcdf038dd3b66506d2e5378aee185b2f0084b7a33';
const manualValueOracleAddress: string = '0x6748B0f4Cd17d1dE0CF718c747D6C0897B2922fb'; // for flex loan 0xfa5d33621f94e596c8d18f3c4a2553ff0f6d538e

test.beforeAll(async () => {
  config = loadConfiguration();

  provider = new ethers.providers.JsonRpcProvider(config.services.ethers.url);
  userSigner = new ethers.Wallet(config.secret.DEPLOYER_PRIVATE_KEY, provider);
});

test.describe.skip('Test Fund', () => {
  test('Test Manual value oracle read functions', async () => {
    const manualValueOracle = new ethers.Contract(manualValueOracleAddress, ABI_MANUAL_VALUE_ORACLE, provider);
    const connectedContract = manualValueOracle.connect(userSigner);
    console.log('Updater: ', (await connectedContract.getUpdater()).toString());
    console.log('Value: ', (await connectedContract.getValue()).toString());
  });

  test('Test Fund Value Calculator', async () => {
    const fundValueCalculator = new ethers.Contract(fundValueCalculatorAddress, ABI_FUND_VALUE_CALCULATOR, provider);
    const connectedContract = fundValueCalculator.connect(userSigner);

    const vaultProxyAddress: string = '0x77b98d8105d0869194f745052896caa6f3dddaf7';

    const [denominationAsset, navValue] = await connectedContract.callStatic.calcNav(vaultProxyAddress);

    console.log('Denomination Asset:', denominationAsset);
    console.log('NAV Value:', navValue.toString());
  });

  test('Test Manual value oracle update value', async () => {
    const manualValueOracle = new ethers.Contract(manualValueOracleAddress, ABI_MANUAL_VALUE_ORACLE, provider);
    const connectedContract = manualValueOracle.connect(userSigner);

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

// see: https://polygonscan.com/address/0xcdf038dd3b66506d2e5378aee185b2f0084b7a33#code
const ABI_FUND_VALUE_CALCULATOR = [
  {
    inputs: [
      {
        internalType: 'address',
        name: '_vaultProxy',
        type: 'address',
      },
    ],
    name: 'calcNav',
    outputs: [
      {
        internalType: 'address',
        name: 'denominationAsset_',
        type: 'address',
      },
      {
        internalType: 'uint256',
        name: 'nav_',
        type: 'uint256',
      },
    ],
    stateMutability: 'nonpayable',
    type: 'function',
  },
];

// see: https://github.com/enzymefinance/protocol/blob/dev/contracts/persistent/arbitrary-value-oracles/manual-value/ManualValueOracleLib.sol
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
