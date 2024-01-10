import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString } from 'class-validator';

import { Enums, Tables } from './supabase';

export const VaultType: readonly Enums<'vault_type'>[] = ['fixed_yield'] as const;
export const VaultStatus: readonly Enums<'vault_status'>[] = ['created', 'ready'] as const;

export class VaultDto implements Tables<'vaults'> {
  @ApiProperty({ description: 'vault id' })
  id: number;

  @ApiProperty({ description: 'vault address' })
  address: string;

  @ApiProperty({ description: 'vault type', enum: VaultType })
  type: Enums<'vault_type'>;

  @ApiProperty({ description: 'vault status', enum: VaultStatus })
  status: Enums<'vault_status'>;

  @ApiProperty({ description: 'vault strategy address' })
  strategy_address: string;

  @ApiProperty({ description: 'vault tenant' })
  tenant: string;

  @ApiProperty({ description: 'vault created at' })
  created_at: string;

  @ApiProperty({ description: 'vault opened at' })
  opened_at: string;

  @ApiProperty({ description: 'vault closed at' })
  closed_at: string;

  constructor(partial: Partial<Tables<'vaults'>>) {
    Object.assign(this, partial);
  }
}

export class UserWalletDto implements Tables<'user_wallets'> {
  @IsNumber()
  @ApiProperty({ description: 'user wallet id' })
  id: number;

  @IsString()
  @ApiProperty({ description: 'user wallet user id' })
  user_id: string;

  @IsString()
  @ApiProperty({ description: 'user wallet address' })
  address: string;

  @IsString()
  @ApiProperty({ description: 'user wallet created at' })
  created_at: string;

  constructor(partial: Partial<Tables<'user_wallets'>>) {
    Object.assign(this, partial);
  }
}
