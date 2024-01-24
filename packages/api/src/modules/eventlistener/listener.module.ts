import { Module, OnModuleInit } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { SupabaseModule } from '../../clients/supabase/supabase.module';

import { ListenerService } from './listener.service';

@Module({
  imports: [SupabaseModule, EthersModule],
  providers: [ListenerService],
  exports: [ListenerService],
})
export class ListenerModule implements OnModuleInit {
  constructor(private listener: ListenerService) {}

  onModuleInit() {
    this.listener.listenToContractEvent();
  }
}
