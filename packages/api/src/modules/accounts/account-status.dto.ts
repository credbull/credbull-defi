import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';

export enum KYCStatus {
  ACTIVE = 'active',
  PENDING = 'pending',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
}

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
