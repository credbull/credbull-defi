import { BigNumber } from 'ethers';
import { describe, expect, it } from 'vitest';

import { DistributionConfig, calculateDistribution } from './vaults.domain';

describe('Vaults Domain', () => {
  const vault = { address: 'vault' };

  it('should calculate distribution so according to the configuration', async () => {
    const expectedAssetsOnMaturity = BigNumber.from(1100);
    const custodianTotalAssets = BigNumber.from(1200);

    const config: DistributionConfig[] = [
      { percentage: 0.8, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(vault, expectedAssetsOnMaturity, custodianTotalAssets, config);

    expect(data?.length).toBe(3);
    expect(data?.[0].address).toBe('vault');
    expect(data?.[0].amount.toString()).toBe('1100');

    expect(data?.[1].address).toBe('treasury');
    expect(data?.[1].amount.toString()).toBe('80');

    expect(data?.[2].address).toBe('activity_reward');
    expect(data?.[2].amount.toString()).toBe('20');
  });

  it('should split the spread dynamically', async () => {
    const expectedAssetsOnMaturity = BigNumber.from(1100);
    const custodianTotalAssets = BigNumber.from(1200);

    const config: DistributionConfig[] = [
      { percentage: 0.2, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 0.5, vault_distribution_entities: { type: 'custodian', address: 'custodian' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { data } = calculateDistribution(vault, expectedAssetsOnMaturity, custodianTotalAssets, config);

    expect(data?.length).toBe(4);

    expect(data?.[1].address).toBe('treasury');
    expect(data?.[1].amount.toString()).toBe('20');

    expect(data?.[2].address).toBe('custodian');
    expect(data?.[2].amount.toString()).toBe('40');

    expect(data?.[3].address).toBe('activity_reward');
    expect(data?.[3].amount.toString()).toBe('40');
  });

  it('should fail if there is not enough in the custodian', async () => {
    const expectedAssetsOnMaturity = BigNumber.from(1100);
    const custodianTotalAssets = BigNumber.from(1000);

    const config: DistributionConfig[] = [
      { percentage: 0.8, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { error } = calculateDistribution(vault, expectedAssetsOnMaturity, custodianTotalAssets, config);

    expect(error).toBeDefined();
  });

  it('should fail if calculation underflows', async () => {
    const expectedAssetsOnMaturity = BigNumber.from(1100);
    const custodianTotalAssets = BigNumber.from(1200);

    const config: DistributionConfig[] = [
      { percentage: 0.008, vault_distribution_entities: { type: 'treasury', address: 'treasury' } },
      { percentage: 1, vault_distribution_entities: { type: 'activity_reward', address: 'activity_reward' } },
    ];

    const { error } = calculateDistribution(vault, expectedAssetsOnMaturity, custodianTotalAssets, config);

    expect(error).toBeDefined();
  });
});
