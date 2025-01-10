// vaultDepositLoader.ts
import { BigNumber } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';

import { logger } from '../utils/logger';

import { Deposit } from './deposit';

const resourcePath = path.join(__dirname, '../../resource');

export function parseFromFile<T extends Deposit>(
  filePath: string,
  depositConstructor: new (id: number, receiver: string, depositAmount: BigNumber) => T,
): T[] {
  logger.info(`Deposit Parser parsing file ${filePath}`);

  const data = fs.readFileSync(path.resolve(resourcePath, filePath), 'utf-8');
  const jsonData = JSON.parse(data);

  if (!jsonData.Deposits || !Array.isArray(jsonData.Deposits)) {
    throw new Error("Invalid format: Expected 'deposits' array in JSON file.");
  }

  return jsonData.Deposits.map((entry: any) => {
    const deposit = entry.Deposit;
    if (!deposit || typeof deposit !== 'object') {
      throw new Error("Invalid format: Each entry in 'Deposits' should contain a 'Deposit' object.");
    }

    // Use the constructor to create the appropriate instance
    return new depositConstructor(deposit.id, deposit.receiver, BigNumber.from(deposit.depositAmount));
  });
}
