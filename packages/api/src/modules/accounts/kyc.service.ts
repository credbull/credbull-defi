import { Injectable } from '@nestjs/common';

import { EthersService } from '../../clients/ethers/ethers.service';

import { KYCStatus } from './account-status.dto';

@Injectable()
export class KycService {
  constructor(private readonly ethers: EthersService) {}

  async status(address: string): Promise<KYCStatus> {
    return (await this.checkOnChain(address)) ? KYCStatus.ACTIVE : KYCStatus.REJECTED;
  }

  private async checkOnChain(address: string): Promise<boolean> {
    return Boolean(address);
  }
}
