// vaultDepositLoader.ts
import { BigNumber } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';

import { VaultDeposit } from './vault-deposit';
import logger from '../utils/logger';

const resourcePath = path.join(__dirname, '../../resource');

export function parseFromFile(filePath: string): VaultDeposit[] {
  logger.info(`Vault Deposit Parser parsing file ${filePath}`);

  const data = fs.readFileSync(path.resolve(resourcePath, filePath), 'utf-8');
  const deposits = JSON.parse(data);

  return deposits.map((deposit: any) => {
    return new VaultDeposit(deposit._id, deposit._receiver, BigNumber.from(deposit._depositAmount));
  });
}
