import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class WalletDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty({ type: String })
  message: string;

  @IsNotEmpty()
  @IsString()
  @ApiProperty({ type: String })
  signature: string;

  @IsString()
  @IsOptional()
  @ApiProperty({ type: String, nullable: true })
  discriminator?: string;

  constructor(partial: Partial<WalletDto>) {
    Object.assign(this, partial);
  }
}
