import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { AccountsController } from './accounts.controller';
import { KycService } from './kyc.service';
import { WalletService } from './wallet.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [KycService, WalletService],
  controllers: [AccountsController],
  exports: [KycService],
})
export class AccountsModule {}
