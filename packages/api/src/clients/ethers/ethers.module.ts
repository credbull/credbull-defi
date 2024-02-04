import { Module } from '@nestjs/common';

import { EthersService } from './ethers.service';

@Module({
  providers: [EthersService],
  exports: [EthersService],
})
export class EthersModule {}
