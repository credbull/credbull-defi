import { ConsoleLogger, Module, Scope } from '@nestjs/common';

import * as logger from '../../utils/logger';

import { EthersService } from './ethers.service';

@Module({
  providers: [EthersService, { provide: ConsoleLogger, useFactory: logger.factory, scope: Scope.TRANSIENT }],
  exports: [EthersService],
})
export class EthersModule {}
