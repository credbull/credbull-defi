import { BigNumber } from 'ethers';

import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

export type DistributionConfig = Pick<Tables<'vault_distribution_configs'>, 'percentage'> & {
  vault_distribution_entities: Pick<Tables<'vault_distribution_entities'>, 'type' | 'address'> | null;
};

export function calculateDistribution(
  custodianTotalAssets: BigNumber,
  distributionConfig: DistributionConfig[],
  parts?: number,
): ServiceResponse<{ address: string; amount: BigNumber }[]> {
  let totalReturns = custodianTotalAssets.div(parts || 1);
  const splits = [];

  try {
    for (const { vault_distribution_entities, percentage } of distributionConfig) {
      const amount = totalReturns.mul(percentage * 100).div(100);

      if (amount.isZero()) continue;

      splits.push({ address: vault_distribution_entities!.address, amount });
      totalReturns = totalReturns.sub(amount);
    }
    return { data: splits };
  } catch (e) {
    return { error: e };
  }
}
