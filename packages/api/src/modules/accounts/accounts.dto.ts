import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

import { WhiteListStatus } from './whiteList.dto';

export class AccountStatusDto {
  @IsEnum(WhiteListStatus)
  @ApiProperty({
    example: 'active',
    description: 'account white list status',
    enum: WhiteListStatus,
    enumName: 'WhiteListStatus',
  })
  status: WhiteListStatus;

  constructor(partial: Partial<AccountStatusDto>) {
    Object.assign(this, partial);
  }
}
