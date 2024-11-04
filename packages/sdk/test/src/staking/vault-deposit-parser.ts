// vaultDepositLoader.ts
import { BigNumber } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';

import { logger } from '../utils/logger';

import { VaultDeposit } from './vault-deposit';

const resourcePath = path.join(__dirname, '../../resource');

export function parseFromFile(filePath: string): VaultDeposit[] {
  logger.info(`Vault Deposit Parser parsing file ${filePath}`);

  const data = fs.readFileSync(path.resolve(resourcePath, filePath), 'utf-8');
  const jsonData = JSON.parse(data);

  if (!jsonData.VaultDeposits || !Array.isArray(jsonData.VaultDeposits)) {
    throw new Error("Invalid format: Expected 'vaultDeposits' array in JSON file.");
  }

  return jsonData.VaultDeposits.map((entry: any) => {
    const deposit = entry.VaultDeposit;
    if (!deposit || typeof deposit !== 'object') {
      throw new Error("Invalid format: Each entry in 'VaultDeposits' should contain a 'VaultDeposit' object.");
    }

    return new VaultDeposit(deposit.id, deposit.receiver, BigNumber.from(deposit.depositAmount));
  });
}
