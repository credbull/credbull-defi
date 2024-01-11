import { IsNumber, IsString } from 'class-validator';

export class CustodianTransferDto {
  @IsString()
  address: string;

  @IsNumber()
  amount: number;

  constructor(partial: Partial<CustodianTransferDto>) {
    Object.assign(this, partial);
  }
}
