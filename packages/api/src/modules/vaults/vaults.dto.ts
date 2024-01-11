import { ApiProperty } from '@nestjs/swagger';
import { IsArray } from 'class-validator';

import { VaultDto } from '../../types/db.dto';
import { Tables } from '../../types/supabase';

export const DISTRIBUTION_CONFIG = [
  { entity: 'treasury', percentage: 0.8, order: 0 },
  { entity: 'activity', percentage: 1, order: 1 },
] as const;

export type DistributionConfig = typeof DISTRIBUTION_CONFIG;

export class VaultsDto {
  @IsArray()
  @ApiProperty({
    description: 'array of vaults',
    isArray: true,
    type: VaultDto,
  })
  data: Tables<'vaults'>[];

  constructor(partial: Partial<VaultsDto>) {
    Object.assign(this, partial);
  }
}
