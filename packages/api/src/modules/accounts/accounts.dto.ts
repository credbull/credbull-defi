import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

import { KYCStatus } from './kyc.dto';

export class AccountStatusDto {
  @IsEnum(KYCStatus)
  @ApiProperty({
    example: 'active',
    description: 'account kyc status',
    enum: KYCStatus,
    enumName: 'KYCStatus',
  })
  status: KYCStatus;

  constructor(partial: Partial<AccountStatusDto>) {
    Object.assign(this, partial);
  }
}
