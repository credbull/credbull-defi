import { createVault } from '../../../../ops/src/create-vault';

import { Schema } from './schema';

export async function createFixedYieldVault(
  config: any,
  treasuryAddress?: string,
  activityRewardAddress?: string,
  collateralPercentage?: number,
): Promise<any> {
  Schema.ADDRESS.optional().parse(treasuryAddress);
  Schema.ADDRESS.optional().parse(activityRewardAddress);
  Schema.PERCENTAGE.optional().parse(collateralPercentage);

  return createVault(config, true, false, false, undefined, undefined, {
    treasuryAddress,
    activityRewardAddress,
    collateralPercentage,
  });
}

export async function createFixedYieldWithUpsideVault(config: any): Promise<any> {
  return createVault(config, true, true, false, 'self', undefined);
}
