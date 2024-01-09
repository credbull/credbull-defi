import { ApiProperty } from '@nestjs/swagger';
import { IsArray } from 'class-validator';

import { Enums, Tables } from '../../types/supabase';

export const type: readonly Enums<'vault_type'>[] = ['fixed_yield'] as const;
export const status: readonly Enums<'vault_status'>[] = ['created', 'ready'] as const;

class VaultDto implements Tables<'vaults'> {
  @ApiProperty({ description: 'vault id' })
  id: number;

  @ApiProperty({ description: 'vault address' })
  address: string;

  @ApiProperty({ description: 'vault type', enum: type })
  type: Enums<'vault_type'>;

  @ApiProperty({ description: 'vault status', enum: status })
  status: Enums<'vault_status'>;

  @ApiProperty({ description: 'vault strategy address' })
  strategy_address: string;

  @ApiProperty({ description: 'vault owner' })
  owner: string;

  @ApiProperty({ description: 'vault created at' })
  created_at: string;

  @ApiProperty({ description: 'vault opened at' })
  opened_at: string;

  @ApiProperty({ description: 'vault closed at' })
  closed_at: string;

  constructor(partial: Tables<'vaults'>) {
    Object.assign(this, partial);
  }
}

export class VaultsDto {
  @IsArray()
  @ApiProperty({
    description: 'array of vaults',
    isArray: true,
    type: VaultDto,
  })
  data: Tables<'vaults'>[];

  constructor(partial: Tables<'vaults'>[]) {
    this.data = partial;
  }
}
