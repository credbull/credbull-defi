import { parseEther } from 'ethers/lib/utils';
import { describe, expect, it } from 'vitest';

import { DistributionConfig, calculateDistribution, calculateProportions } from './vaults.domain';

describe('Vaults Domain', () => {
  it('should calculate distribution so according to the configuration', async () => {
    const custodianTotalAssets = parseEther('100');

    const config: DistributionConfig[] = [
      { percentage: 0.8, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(custodianTotalAssets, config);

    expect(data?.length).toBe(2);
    expect(data?.[0].address).toBe('treasury');
    expect(data?.[0].amount).toStrictEqual(parseEther('80'));

    expect(data?.[1].address).toBe('activity_reward');
    expect(data?.[1].amount).toStrictEqual(parseEther('20'));
  });

  it('should split the spread dynamically', async () => {
    const custodianTotalAssets = parseEther('100');

    const config: DistributionConfig[] = [
      { percentage: 0.2, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 0.5, vault_distribution_entities: { type: 'custodian', address: 'custodian' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(custodianTotalAssets, config);

    expect(data?.length).toBe(3);

    expect(data?.[0].address).toBe('treasury');
    expect(data?.[0].amount).toStrictEqual(parseEther('20'));

    expect(data?.[1].address).toBe('custodian');
    expect(data?.[1].amount).toStrictEqual(parseEther('40'));

    expect(data?.[2].address).toBe('activity_reward');
    expect(data?.[2].amount).toStrictEqual(parseEther('40'));
  });

  it('should return empty split if there is no asset in the custodian', async () => {
    const custodianTotalAssets = parseEther('0');

    const config: DistributionConfig[] = [
      { percentage: 0.8, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(custodianTotalAssets, config);

    expect(data?.length).toBe(0);
  });

  it('should fail if calculation underflows', async () => {
    const custodianTotalAssets = parseEther('100');

    const config: DistributionConfig[] = [
      { percentage: 0.008, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { error } = calculateDistribution(custodianTotalAssets, config);

    expect(error).toBeDefined();
  });

  it('should calculate the correct proportion of the total custodian amount', async () => {
    const custodianAmount = parseEther('3600');

    const config = [
      { custodianAmount, amount: parseEther('1100') },
      { custodianAmount, amount: parseEther('2200') },
    ];

    const proportions = calculateProportions(config);

    expect(proportions[0]).toStrictEqual(parseEther('100'));
    expect(proportions[1]).toStrictEqual(parseEther('200'));
  });
});
