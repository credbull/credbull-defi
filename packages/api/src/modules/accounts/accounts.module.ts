import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { AccountsController } from './accounts.controller';
import { KycService } from './kyc.service';
import { WalletsService } from './wallets.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [KycService, WalletsService],
  controllers: [AccountsController],
  exports: [KycService, WalletsService],
})
export class AccountsModule {}
