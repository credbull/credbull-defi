import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString } from 'class-validator';
import { BigNumber } from 'ethers';

export class VaultParamsDto {
  @ApiProperty({ type: String, example: '0xa0eC68DB71DD667a09863478fa0dCfC7b525871f' })
  @IsString()
  owner: string;

  @ApiProperty({ type: String, example: '0x5FbDB2315678afecb367f032d93F642f64180aa3' })
  @IsString()
  asset: string;

  @ApiProperty({ type: String, example: 'Test share' })
  @IsString()
  shareName: string;

  @ApiProperty({ type: String, example: 'Test symbol' })
  @IsString()
  shareSymbol: string;

  @ApiProperty({ type: BigNumber, example: '1705276800' })
  @IsNumber()
  openAt: BigNumber;

  @ApiProperty({ type: BigNumber, example: '1705286800' })
  @IsNumber()
  closesAt: BigNumber;

  @ApiProperty({ type: String, example: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' })
  @IsString()
  custodian: string;

  @ApiProperty({ type: String, example: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512' })
  @IsString()
  kycProvider: string;

  @ApiProperty({ type: String, example: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' })
  @IsString()
  treasury: string;

  @ApiProperty({ type: String, example: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8' })
  @IsString()
  activityReward: string;

  @ApiProperty({ type: BigNumber, example: '10' })
  @IsNumber()
  promisedYield: BigNumber;

  constructor(partial: Partial<VaultParamsDto>) {
    Object.assign(this, partial);
  }
}
