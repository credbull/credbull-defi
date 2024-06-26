import { CredbullFixedYieldVault, CredbullFixedYieldVaultWithUpside, ERC20 } from '@credbull/contracts';
import { BigNumber } from 'ethers';
import { formatUnits } from 'ethers/lib/utils';

export function displayValueFor(decimals: number): (amount: BigNumber) => string {
  return (amount) => formatUnits(amount, decimals);
}

async function internalDescribeVault(vault: CredbullFixedYieldVault): Promise<string> {
  return `
  Address: ${vault.address}
  Name: ${await vault.name()}
  Symbol: ${await vault.symbol()}
  Total Supply: ${await vault.totalSupply()}
  Matured?: ${await vault.isMatured()}
  Paused?: ${await vault.paused()}
  Asset: ${await vault.asset()}
  Total Assets: ${await vault.totalAssets()}
  Total Assets Deposited: ${await vault.totalAssetDeposited()}`;
}

export async function describeFYVault(vault: CredbullFixedYieldVault): Promise<string> {
  return `
  Type: Fixed Yield\
  ${await internalDescribeVault(vault)}
  `;
}

export async function describeFYWUVault(vault: CredbullFixedYieldVaultWithUpside): Promise<string> {
  return `
  Type: Fixed Yield With Upside\
  ${await internalDescribeVault(vault as CredbullFixedYieldVault)}
  TWAP: ${await vault.twap()}`;
}

export async function describeToken(token: ERC20): Promise<string> {
  return `
  Address: ${token.address}
  Name: ${await token.name()}
  Symbol: ${await token.symbol()}
  Decimals: ${await token.decimals()}
  Total Supply: ${await token.totalSupply()}`;
}

export function balanceLoggerFactory(
  shareBalance: (address: string) => Promise<string>,
  assetBalance: (address: string) => Promise<string>,
  actors: string[][],
  tokenBalance?: (address: string) => Promise<string>,
): () => Promise<void> {
  return async function balanceLogger(): Promise<void> {
    const balancesFor = async (whom: string, address: string) => {
      const sb = await shareBalance(address);
      const ab = await assetBalance(address);
      const tb = tokenBalance ? await tokenBalance!(address) : undefined;
      console.log(`  ${whom}'s Share/Asset${tb ? '/Token' : ''} balance= ${sb} / ${ab}${tb ? ' / ' + tb : ''}`);
    };

    console.log('-'.repeat(80));
    for (const i in actors) {
      const [label, address] = actors[i];
      await balancesFor(label, address);
    }
    console.log('-'.repeat(80));
  };
}
