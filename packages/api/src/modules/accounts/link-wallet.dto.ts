import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsString } from 'class-validator';

import { Tables } from '../../types/supabase';

export class LinkWalletDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty({ type: String })
  message: string;

  @IsNotEmpty()
  @IsString()
  @ApiProperty({ type: String })
  signature: string;

  constructor(partial: Partial<LinkWalletDto>) {
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
