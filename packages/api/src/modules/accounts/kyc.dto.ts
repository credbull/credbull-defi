import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export enum KYCStatus {
  ACTIVE = 'active',
  PENDING = 'pending',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
}

export class WhitelistAccountDto {
  @IsString()
  @ApiProperty({
    example: '0x0000000',
    description: 'wallet address to whitelist',
  })
  address: string;

  @IsString()
  @ApiProperty({
    description: 'user id',
  })
  user_id: string;

  constructor(partial: Partial<WhitelistAccountDto>) {
    Object.assign(this, partial);
  }
}
