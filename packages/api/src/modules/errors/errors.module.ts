import { Module } from '@nestjs/common';

import { EthersModule } from '../../clients/ethers/ethers.module';

import { ErrorHandlerService } from './errors.service';

@Module({
  imports: [EthersModule],
  providers: [ErrorHandlerService],
  exports: [ErrorHandlerService],
})
export class ErrorsModule {}
