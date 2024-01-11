import { Module } from '@nestjs/common';

import { EthersService } from '../../clients/ethers/ethers.service';

import { MetaTxController } from './metatx.controller';
import { MetaTxService } from './metatx.service';

@Module({
  controllers: [MetaTxController],
  providers: [MetaTxService, EthersService],
})
export class MetaTxModule {}
