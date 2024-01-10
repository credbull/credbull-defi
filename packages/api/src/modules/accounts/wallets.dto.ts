import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class WalletDto {
  @IsNotEmpty()
  @IsString()
  @ApiProperty({ type: String })
  message: string;

  @IsNotEmpty()
  @IsString()
  @ApiProperty({ type: String })
  signature: string;

  constructor(partial: Partial<WalletDto>) {
    Object.assign(this, partial);
  }
}
