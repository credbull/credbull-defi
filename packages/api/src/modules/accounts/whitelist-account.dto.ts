import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class WhitelistAccountDto {
  @IsString()
  @ApiProperty({
    example: '0x0000000',
    description: 'wallet address to whitelist',
  })
  address: string;

  constructor(partial: Partial<WhitelistAccountDto>) {
    Object.assign(this, partial);
  }
}
