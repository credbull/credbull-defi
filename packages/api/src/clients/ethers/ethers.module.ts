import { Module, OnModuleInit } from '@nestjs/common';

import { EthersService } from './ethers.service';

@Module({
  providers: [EthersService],
  exports: [EthersService],
})
export class EthersModule implements OnModuleInit {
  onModuleInit() {
    console.log('On ethers module init');
  }
}
