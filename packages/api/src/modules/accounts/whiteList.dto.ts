import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export enum WhiteListStatus {
  ACTIVE = 'active',
  PENDING = 'pending',
  REJECTED = 'rejected',
}

export class WhiteListAccountDto {
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

  constructor(partial: Partial<WhiteListAccountDto>) {
    Object.assign(this, partial);
  }
}
