import { ConsoleLogger, Module, Scope } from '@nestjs/common';

import { TomlConfigService } from '../../utils/config';
import * as logger from '../../utils/logger';

import { EthersService } from './ethers.service';

@Module({
  providers: [
    EthersService,
    TomlConfigService,
    { provide: ConsoleLogger, useFactory: logger.factory, scope: Scope.TRANSIENT },
  ],
  exports: [EthersService],
})
export class EthersModule {}
