import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { VaultsController } from './vaults.controller';
import { VaultsService } from './vaults.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [VaultsService],
  controllers: [VaultsController],
})
export class VaultsModule {}
