import {
  CredbullFixedYieldVault,
  CredbullFixedYieldVaultWithUpside,
  MockStablecoin__factory,
} from '@credbull/contracts';
import { BigNumber, ContractTransaction, Signer, Wallet, ethers } from 'ethers';

import { Schema } from './schema';

export const TRASH_ADDRESS = '0xcabE80b332Aa9d900f5e32DF51cb0Bc5b276c556';

export async function __mockMint(
  to: string,
  amount: BigNumber,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  signer: Signer | ethers.providers.Provider,
): Promise<ContractTransaction> {
  return vault.asset().then(async (address) => {
    const asset = MockStablecoin__factory.connect(address, signer);
    return asset.mint(to, amount);
  });
}

export async function __mockMintToken(
  to: string,
  amount: BigNumber,
  vault: CredbullFixedYieldVaultWithUpside,
  signer: Signer | ethers.providers.Provider,
): Promise<ContractTransaction> {
  return vault.token().then(async (address) => {
    const token = MockStablecoin__factory.connect(address, signer);
    return token.mint(to, amount);
  });
}

export function signerForAdmin(config: any): Signer {
  Schema.CONFIG_API_URL.merge(Schema.CONFIG_ADMIN_PRIVATE_KEY).parse(config);

  return new Wallet(config.secret.ADMIN_PRIVATE_KEY, new ethers.providers.JsonRpcProvider(config.api.url));
}

export async function toggleMaturityCheck(
  config: any,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  value: boolean,
): Promise<ContractTransaction> {
  return vault.connect(signerForAdmin(config)).toggleMaturityCheck(value);
}

export async function toggleWindowCheck(
  config: any,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  value: boolean,
): Promise<ContractTransaction> {
  return vault.connect(signerForAdmin(config)).toggleWindowCheck(value);
}
