import { Injectable, OnModuleInit, Scope } from '@nestjs/common';
import { errors } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';

@Injectable({ scope: Scope.DEFAULT })
export class ErrorHandlerService implements OnModuleInit {
  onModuleInit() {
    console.log('Error handler service init...');
  }

  constructor(private readonly ethers: EthersService) {}

  async handleError(error: any) {
    console.log(error);

    if (error?.code === errors.NETWORK_ERROR) {
      await this.ethers.initProvider();
    }
  }
}
