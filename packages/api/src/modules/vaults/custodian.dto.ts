import { IsNumber, IsString } from 'class-validator';
import { BigNumber } from 'ethers';

export class CustodianTransferDto {
  @IsNumber()
  vaultId: number;

  @IsString()
  address: string;

  @IsNumber()
  amount: BigNumber;

  constructor(partial: Partial<CustodianTransferDto>) {
    this.amount = BigNumber.from(partial.amount);
    this.vaultId = partial.vaultId!;
    this.address = partial.address!;
  }
}
