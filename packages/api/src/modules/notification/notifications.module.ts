import { ConsoleLogger, Module, Scope } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';
import * as logger from '../../utils/logger';

import { NotificationsService } from './notifications.service';

@Module({
  imports: [SupabaseModule, EthersModule, ConfigModule],
  providers: [NotificationsService, { provide: ConsoleLogger, useFactory: logger.factory, scope: Scope.TRANSIENT }],
  exports: [NotificationsService],
})
export class NotificationsModule {}
