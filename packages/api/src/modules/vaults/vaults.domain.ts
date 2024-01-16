import { BigNumber } from 'ethers';

import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

export type DistributionConfig = Pick<Tables<'vault_distribution_configs'>, 'percentage'> & {
  vault_distribution_entities: Pick<Tables<'vault_distribution_entities'>, 'type' | 'address'> | null;
};

export function calculateDistribution(
  vault: Pick<Tables<'vaults'>, 'address'>,
  expectedAssetsOnMaturity: BigNumber,
  custodianTotalAssets: BigNumber,
  distributionConfig: DistributionConfig[],
): ServiceResponse<{ address: string; amount: BigNumber }[]> {
  try {
    if (custodianTotalAssets.lt(expectedAssetsOnMaturity))
      return { error: new Error('Custodian amount should be bigger or same as expected amount') };

    let totalReturns = custodianTotalAssets.sub(expectedAssetsOnMaturity);
    const splits = [{ address: vault.address, amount: expectedAssetsOnMaturity }];

    for (const { vault_distribution_entities, percentage } of distributionConfig) {
      const amount = totalReturns.mul(percentage * 100).div(100);

      splits.push({ address: vault_distribution_entities!.address, amount });
      totalReturns = totalReturns.sub(amount);
    }
    return { data: splits };
  } catch (e) {
    return { error: e };
  }
}
