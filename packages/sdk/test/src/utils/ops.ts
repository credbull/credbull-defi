import { createVault } from '../../../../ops/src/create-vault';

import { Schema } from './schema';

export async function createFixedYieldVault(
  config: any,
  treasuryAddress: string,
  activityRewardAddress: string,
  collateralPercentage: number,
): Promise<any> {
  Schema.ADDRESS.parse(treasuryAddress);
  Schema.ADDRESS.parse(activityRewardAddress);
  Schema.PERCENTAGE.parse(collateralPercentage);

  const modifiedConfig = {
    ...config,
    evm: {
      ...config.evm,
      address: {
        ...config.evm.address,
        treasury: treasuryAddress,
        activity_reward: activityRewardAddress,
      },
    },
    operation: {
      ...config.operation,
      createVault: {
        ...config.operation.createVault,
        collateral_percentage: collateralPercentage,
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
  collateralPercentage?: number,
): Promise<any> {
  Schema.ADDRESS.optional().parse(upsideVaultAddress);
  Schema.ADDRESS.optional().parse(treasuryAddress);
  Schema.ADDRESS.optional().parse(activityRewardAddress);
  Schema.PERCENTAGE.optional().parse(collateralPercentage);

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
        ...(collateralPercentage ? { collateral_percentage: collateralPercentage } : {}),
      },
    },
  };

  return createVault(modifiedConfig, true, true, false, upsideVaultAddress || 'self', undefined);
}
