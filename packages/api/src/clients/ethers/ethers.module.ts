import { ConsoleLogger, Module, Scope } from '@nestjs/common';

import * as logger from '../../utils/logger';
import { ConfigurationModule } from '../../utils/module';

import { EthersService } from './ethers.service';

@Module({
  imports: [ConfigurationModule],
  providers: [EthersService, { provide: ConsoleLogger, useFactory: logger.factory, scope: Scope.TRANSIENT }],
  exports: [EthersService],
})
export class EthersModule {}
