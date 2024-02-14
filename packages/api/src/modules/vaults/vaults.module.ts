import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';
import { CronStrategy } from '../../utils/guards';

import { CustodianService } from './custodian.service';
import { SyncVaultsService } from './sync-vaults.service';
import { UpdateUpsideTwapService } from './update-upside-twap.service';
import { VaultsController } from './vaults.controller';
import { VaultsService } from './vaults.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [VaultsService, CustodianService, CronStrategy, SyncVaultsService, UpdateUpsideTwapService],
  controllers: [VaultsController],
  exports: [VaultsService, CustodianService, SyncVaultsService, UpdateUpsideTwapService],
})
export class VaultsModule {}
