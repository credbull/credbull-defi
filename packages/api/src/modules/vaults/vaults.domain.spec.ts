import { parseUnits } from 'ethers/lib/utils';
import { describe, expect, it } from 'vitest';

import { DistributionConfig, calculateDistribution, calculateProportions } from './vaults.domain';

describe('Vaults Domain', () => {
  it('should calculate distribution so according to the configuration', async () => {
    const custodianTotalAssets = parseUnits('100', 'mwei');

    const config: DistributionConfig[] = [
      { percentage: 0.8, vault_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(custodianTotalAssets, config);

    expect(data?.length).toBe(2);
    expect(data?.[0].address).toBe('treasury');
    expect(data?.[0].amount).toStrictEqual(parseUnits('80', 'mwei'));

    expect(data?.[1].address).toBe('activity_reward');
    expect(data?.[1].amount).toStrictEqual(parseUnits('20', 'mwei'));
  });

  it('should split the spread dynamically', async () => {
    const custodianTotalAssets = parseUnits('100', 'mwei');

    const config: DistributionConfig[] = [
      { percentage: 0.2, vault_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 0.5, vault_entities: { type: 'custodian', address: 'custodian' } },
      { percentage: 1, vault_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(custodianTotalAssets, config);

    expect(data?.length).toBe(3);

    expect(data?.[0].address).toBe('treasury');
    expect(data?.[0].amount).toStrictEqual(parseUnits('20', 'mwei'));

    expect(data?.[1].address).toBe('custodian');
    expect(data?.[1].amount).toStrictEqual(parseUnits('40', 'mwei'));

    expect(data?.[2].address).toBe('activity_reward');
    expect(data?.[2].amount).toStrictEqual(parseUnits('40', 'mwei'));
  });

  it('should return empty split if there is no asset in the custodian', async () => {
    const custodianTotalAssets = parseUnits('0');

    const config: DistributionConfig[] = [
      { percentage: 0.8, vault_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(custodianTotalAssets, config);

    expect(data?.length).toBe(0);
  });

  it('should fail if calculation underflows', async () => {
    const custodianTotalAssets = parseUnits('100', 'mwei');

    const config: DistributionConfig[] = [
      { percentage: 0.008, vault_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { error } = calculateDistribution(custodianTotalAssets, config);

    expect(error).toBeDefined();
  });

  it('should calculate the correct proportion of the total custodian amount', async () => {
    const custodianAmount = parseUnits('3600', 'mwei');

    const config = [
      { custodianAmount, amount: parseUnits('1100', 'mwei') },
      { custodianAmount, amount: parseUnits('2200', 'mwei') },
    ];

    const proportions = calculateProportions(config);

    expect(proportions[0]).toStrictEqual(parseUnits('100', 'mwei'));
    expect(proportions[1]).toStrictEqual(parseUnits('200', 'mwei'));
  });
});
