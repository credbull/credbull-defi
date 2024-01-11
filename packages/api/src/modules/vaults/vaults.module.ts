import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { CustodianService } from './custodian.service';
import { VaultsController } from './vaults.controller';
import { VaultsService } from './vaults.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [VaultsService, CustodianService],
  controllers: [VaultsController],
  exports: [VaultsService, CustodianService],
})
export class VaultsModule {}
