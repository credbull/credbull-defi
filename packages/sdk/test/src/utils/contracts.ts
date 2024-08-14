import { CredbullFixedYieldVault, CredbullFixedYieldVaultWithUpside, SimpleUSDC__factory } from '@credbull/contracts';
import { BigNumber, ContractTransaction, Signer, ethers } from 'ethers';

import { User } from './user';

export const TRASH_ADDRESS = '0xcabE80b332Aa9d900f5e32DF51cb0Bc5b276c556';

export async function __mockMint(
  to: string,
  amount: BigNumber,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  signer: Signer | ethers.providers.Provider,
): Promise<ContractTransaction> {
  return vault.asset().then(async (address) => {
    const asset = SimpleUSDC__factory.connect(address, signer);
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
    const token = SimpleUSDC__factory.connect(address, signer);
    return token.mint(to, amount);
  });
}

export async function setMaturityCheck(
  admin: User,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  value: boolean,
): Promise<ContractTransaction> {
  return vault.connect(admin.testSigner.getDelegate()).setMaturityCheck(value);
}

export async function toggleWindowCheck(
  admin: User,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
) {
    return vault.connect(admin.testSigner.getDelegate()).toggleWindowCheck();
}
