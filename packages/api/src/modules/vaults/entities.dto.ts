import { ApiProperty } from '@nestjs/swagger';
import { IsArray } from 'class-validator';

import { Tables } from '../../types/supabase';

export class EntitiesDto {
  @IsArray()
  @ApiProperty({
    description: 'vault entities',
    type: [EntitiesDto],
  })
  data: Tables<'vault_entities'>[];

  constructor(partial: Partial<EntitiesDto>) {
    Object.assign(this, partial);
  }
}
