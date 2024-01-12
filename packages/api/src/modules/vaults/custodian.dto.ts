import { IsNumber, IsString } from 'class-validator';
import { BigNumber } from 'ethers';

export class CustodianTransferDto {
  @IsString()
  address: string;

  @IsNumber()
  amount: BigNumber;

  constructor(partial: Partial<CustodianTransferDto>) {
    this.amount = BigNumber.from(partial.amount);
    this.address = partial.address!;
  }
}
