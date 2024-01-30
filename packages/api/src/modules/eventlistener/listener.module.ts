import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { ErrorsModule } from '../errors/errors.module';

import { SyncEventService } from './syncEvent.service';

@Module({
  imports: [EthersModule, ErrorsModule],
  providers: [SyncEventService],
  exports: [SyncEventService],
})
export class ListenerModule {}
