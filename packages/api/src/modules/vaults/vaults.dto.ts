import { ApiProperty } from '@nestjs/swagger';
import { IsArray } from 'class-validator';

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
