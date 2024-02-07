import { BigNumber } from 'ethers';
import { formatEther, parseEther } from 'ethers/lib/utils';
import { z } from 'zod';

import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

import { CustodianTransferDto } from './custodian.dto';

export const DistributionConfigSchema = z.object({
  percentage: z.number(),
  vault_entities: z.object({
    type: z.string(),
    address: z.string(),
  }),
}) as z.ZodSchema<DistributionConfig>;

export type DistributionConfig = Pick<Tables<'vault_distribution_configs'>, 'percentage'> & {
  vault_entities: Pick<Tables<'vault_entities'>, 'type' | 'address'> | null;
};

export type CalculateProportionsData = { custodianAmount: BigNumber; amount: BigNumber };

const toNumber = (n: BigNumber) => Number(formatEther(n));

export function calculateProportions(data: CalculateProportionsData[]) {
  const totalExpected = data.reduce((acc, cur) => acc + toNumber(cur.amount), 0);
  const percentages = data.map((cur) => (toNumber(cur.amount) * 100) / totalExpected);

  return data
    .map((cur, i) => ((toNumber(cur.custodianAmount) - totalExpected) * percentages[i]) / 100)
    .map((n) => parseEther(Math.round(n).toString()));
}

export function prepareDistributionTransfers(
  vault: Tables<'vaults'>,
  custodianAssets: BigNumber,
  custodianAddress: string,
  distributionConfig: DistributionConfig[],
): ServiceResponse<CustodianTransferDto[]> {
  const splits = calculateDistribution(custodianAssets, distributionConfig);

  if (splits.error) return splits;

  const dtos: CustodianTransferDto[] = splits.data?.map((split) => ({
    custodian_address: custodianAddress,
    asset_address: vault.asset_address,
    vault_id: vault.id,
    ...split,
  }));

  return { data: dtos };
}

export function calculateDistribution(
  custodianAssets: BigNumber,
  distributionConfig: DistributionConfig[],
): ServiceResponse<{ address: string; amount: BigNumber }[]> {
  let totalReturns = custodianAssets;
  const splits = [];

  try {
    for (const { vault_entities, percentage } of distributionConfig) {
      const amount = totalReturns.mul(percentage * 100).div(100);

      if (amount.isZero()) continue;

      splits.push({ address: vault_entities!.address, amount });
      totalReturns = totalReturns.sub(amount);
    }
    return { data: splits };
  } catch (e) {
    return { error: e };
  }
}
