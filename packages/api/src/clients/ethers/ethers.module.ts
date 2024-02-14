import { ConsoleLogger, Module } from '@nestjs/common';

import * as logger from '../../utils/logger';

import { EthersService } from './ethers.service';

@Module({
  providers: [EthersService, { provide: ConsoleLogger, useFactory: logger.factory }],
  exports: [EthersService],
})
export class EthersModule {}
