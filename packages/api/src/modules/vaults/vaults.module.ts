import { ConsoleLogger, Module, Scope } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';
import { CronStrategy } from '../../utils/guards';
import * as logger from '../../utils/logger';

import { CustodianService } from './custodian.service';
import { MatureVaultsService } from './mature-vaults.service';
import { SyncVaultsService } from './sync-vaults.service';
import { UpdateUpsideTwapService } from './update-upside-twap.service';
import { VaultsController } from './vaults.controller';
import { VaultsService } from './vaults.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [
    VaultsService,
    MatureVaultsService,
    CustodianService,
    CronStrategy,
    SyncVaultsService,
    UpdateUpsideTwapService,
    { provide: ConsoleLogger, useFactory: logger.factory, scope: Scope.TRANSIENT },
  ],
  controllers: [VaultsController],
  exports: [VaultsService, MatureVaultsService, CustodianService, SyncVaultsService, UpdateUpsideTwapService],
})
export class VaultsModule {}
