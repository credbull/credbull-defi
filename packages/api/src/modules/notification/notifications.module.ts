import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { NotificationsService } from './notifications.service';

@Module({
  imports: [SupabaseModule, EthersModule, ConfigModule],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
