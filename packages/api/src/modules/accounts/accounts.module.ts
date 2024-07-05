import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';
import { ConfigurationModule } from '../../utils/module';
import { VaultsModule } from '../vaults/vaults.module';
import { VaultsService } from '../vaults/vaults.service';

import { AccountsController } from './accounts.controller';
import { WalletsService } from './wallets.service';
import { WhiteListService } from './whiteList.service';

@Module({
  imports: [ConfigurationModule, SupabaseModule, EthersModule, VaultsModule],
  providers: [WhiteListService, WalletsService, VaultsService],
  controllers: [AccountsController],
  exports: [WhiteListService, WalletsService],
})
export class AccountsModule {}
