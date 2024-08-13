import { createVault } from '../../../../ops/src/create-vault';

import { Schema } from './schema';

export async function createFixedYieldVault(
  config: any,
  treasuryAddress?: string,
  activityRewardAddress?: string,
  upsidePercentage?: number,
): Promise<any> {
  Schema.ADDRESS.optional().parse(treasuryAddress);
  Schema.ADDRESS.optional().parse(activityRewardAddress);
  Schema.PERCENTAGE.optional().parse(upsidePercentage);

  const modifiedConfig = {
    ...config,
    evm: {
      ...config.evm,
      address: {
        ...config.evm.address,
        ...(treasuryAddress ? { treasury: treasuryAddress } : {}),
        ...(activityRewardAddress ? { activity_reward: activityRewardAddress } : {}),
      },
    },
    operation: {
      ...config.operation,
      createVault: {
        ...config.operation.createVault,
        ...(upsidePercentage ? { upside_percentage: upsidePercentage } : {}),
      },
    },
  };

  return createVault(modifiedConfig, true, false, false, undefined, undefined);
}

export async function createFixedYieldWithUpsideVault(
  config: any,
  upsideVaultAddress?: string,
  treasuryAddress?: string,
  activityRewardAddress?: string,
  upsidePercentage?: number,
): Promise<any> {
  Schema.ADDRESS.optional().parse(upsideVaultAddress);
  Schema.ADDRESS.optional().parse(treasuryAddress);
  Schema.ADDRESS.optional().parse(activityRewardAddress);
  Schema.PERCENTAGE.optional().parse(upsidePercentage);

  const modifiedConfig = {
    ...config,
    evm: {
      ...config.evm,
      address: {
        ...config.evm.address,
        ...(treasuryAddress ? { treasury: treasuryAddress } : {}),
        ...(activityRewardAddress ? { activity_reward: activityRewardAddress } : {}),
      },
    },
    operation: {
      ...config.operation,
      createVault: {
        ...config.operation.createVault,
        ...(upsidePercentage ? { upside_percentage: upsidePercentage } : {}),
      },
    },
  };

  return createVault(modifiedConfig, true, true, false, upsideVaultAddress || 'self', undefined);
}
