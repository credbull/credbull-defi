import { Module, OnModuleInit } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { ListenerService } from './listener.service';
import { SyncEventService } from './syncEvent.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [ListenerService, SyncEventService],
  exports: [ListenerService, SyncEventService],
})
export class ListenerModule implements OnModuleInit {
  constructor(private listener: ListenerService) {}

  async onModuleInit(): Promise<void> {
    await this.listener.listenToContractEvent();
  }
}
