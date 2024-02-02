import { ApiProperty } from '@nestjs/swagger';
import { Expose, Type } from 'class-transformer';
import { IsArray, IsNumber, IsString } from 'class-validator';
import { BigNumber } from 'ethers';

import { VaultDto } from '../../types/db.dto';
import { Tables } from '../../types/supabase';

export class VaultsDto {
  @IsArray()
  @ApiProperty({
    description: 'array of vaults',
    isArray: true,
    type: VaultDto,
  })
  data: Tables<'vaults'>[];

  constructor(partial: Partial<VaultsDto>) {
    Object.assign(this, partial);
  }
}

export class EntitiesDto {
  @Expose()
  type: 'treasury' | 'custodian' | 'activity_reward' | 'vault' | 'kyc_provider';

  @Expose()
  address: string;

  @Expose()
  percentage: number;
}

export class VaultParamsDto extends EntitiesDto {
  @ApiProperty({ type: String, example: '0xa0eC68DB71DD667a09863478fa0dCfC7b525871f' })
  @IsString()
  owner: string;

  @ApiProperty({ type: String, example: '0xcabE80b332Aa9d900f5e32DF51cb0Bc5b276c556' })
  @IsString()
  operator: string;

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
  depositOpensAt: BigNumber;

  @ApiProperty({ type: BigNumber, example: '1705286800' })
  @IsNumber()
  depositClosesAt: BigNumber;

  @ApiProperty({ type: BigNumber, example: '1705276800' })
  @IsNumber()
  redemptionOpensAt: BigNumber;

  @ApiProperty({ type: BigNumber, example: '1705286800' })
  @IsNumber()
  redemptionClosesAt: BigNumber;

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

  @ApiProperty({
    type: EntitiesDto,
    example: [{ type: 'treasury', address: '0x70997970C51812dc3A010C7d01b50e0d17dc79C8', percentage: 0.8 }],
  })
  @IsArray()
  @Type(() => EntitiesDto)
  entities: EntitiesDto[];

  constructor(partial: Partial<VaultParamsDto>) {
    super();
    Object.assign(this, partial);
  }
}
