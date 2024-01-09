import { Module } from '@nestjs/common';

import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { VaultsController } from './vaults.controller';

@Module({
  imports: [SupabaseModule],
  controllers: [VaultsController],
})
export class VaultsModule {}
