import { CredbullFixedYieldVault, ERC20 } from '@credbull/contracts';
import { BigNumber } from 'ethers';

export function displayValueFor(decimals: number): (amount: BigNumber) => String {
  return (amount) => amount.div(10 ** decimals).toString();
}

export async function describeVault(vault: CredbullFixedYieldVault): Promise<string> {
  return `
  Address: ${vault.address}
  Name: ${await vault.name()}
  Symbol: ${await vault.symbol()}
  Total Supply: ${await vault.totalSupply()}
  Matured?: ${await vault.isMatured()}
  Paused?: ${await vault.paused()}
  Asset: ${await vault.asset()}
  Total Assets: ${await vault.totalAssets()}
  Total Assets Deposited: ${await vault.totalAssetDeposited()}
  `;
}

export async function describeToken(token: ERC20): Promise<string> {
  return `
  Address: ${token.address}
  Name: ${await token.name()}
  Symbol: ${await token.symbol()}
  Decimals: ${await token.decimals()}
  Total Supply: ${await token.totalSupply()}
  `;
}
