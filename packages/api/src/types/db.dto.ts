import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString } from 'class-validator';
import { z } from 'zod';

import { Enums, Tables } from './supabase';

export const PartnerTypes = ['channel'] as const;
export type PartnerType = (typeof PartnerTypes)[number];

export const VaultType = ['fixed_yield', 'fixed_yield_upside'] as const;

export const VaultStatus = ['created', 'ready'] as const;

export const VaultSchema = z.object({
  id: z.number(),
  address: z.string(),
  type: z.enum(VaultType),
  status: z.enum(VaultStatus),
  strategy_address: z.string(),
  asset_address: z.string(),
  tenant: z.string(),
  created_at: z.string(),
  deposits_opened_at: z.string(),
  deposits_closed_at: z.string(),
  redemptions_opened_at: z.string(),
  redemptions_closed_at: z.string(),
}) as z.ZodSchema<Tables<'vaults'>>;

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

  @ApiProperty({ description: 'vault asset address' })
  asset_address: string;

  @ApiProperty({ description: 'vault tenant' })
  tenant: string;

  @ApiProperty({ description: 'vault created at' })
  created_at: string;

  @ApiProperty({ description: 'vault deposits opened at' })
  deposits_opened_at: string;

  @ApiProperty({ description: 'vault deposits closed at' })
  deposits_closed_at: string;

  @ApiProperty({ description: 'vault redemptions opened at' })
  redemptions_opened_at: string;

  @ApiProperty({ description: 'vault redemptions closed at' })
  redemptions_closed_at: string;

  constructor(partial: Partial<Tables<'vaults'>>) {
    Object.assign(this, partial);
  }
}

export const UserWalletSchema = z.object({
  id: z.number(),
  user_id: z.string(),
  address: z.string(),
  created_at: z.string(),
  discriminator: z.string().optional(),
}) as z.ZodSchema<Tables<'user_wallets'>>;

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

  @IsString()
  @IsOptional()
  @ApiProperty({ description: 'a custom discriminator for the wallet', nullable: true })
  discriminator: string;

  constructor(partial: Partial<Tables<'user_wallets'>>) {
    Object.assign(this, partial);
  }
}
