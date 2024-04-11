import { IsNumber, IsString } from 'class-validator';
import { BigNumber } from 'ethers';

export class CustodianTransferDto {
  @IsNumber()
  vault_id: number;

  @IsString()
  address: string;

  @IsString()
  asset_address: string;

  @IsString()
  custodian_address: string;

  @IsNumber()
  amount: BigNumber;

  constructor(partial: CustodianTransferDto) {
    this.amount = BigNumber.from(partial.amount);
    this.vault_id = partial.vault_id;
    this.address = partial.address;
    this.asset_address = partial.asset_address;
    this.custodian_address = partial.custodian_address;
  }
}
