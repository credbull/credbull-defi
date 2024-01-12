import { MockStablecoin__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BigNumber } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse, fromPromiseToReceipt, fromPromiseToResponse } from '../../types/responses';

import { CustodianTransferDto } from './custodian.dto';

@Injectable()
export class CustodianService {
  private usdcAddress: string;

  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly config: ConfigService,
  ) {
    this.config.getOrThrow<string>('USDC_CONTRACT_ADDRESS');
  }

  async totalAssets(): Promise<ServiceResponse<BigNumber>> {
    const asset = this.asset();
    const address = await this.address();

    return fromPromiseToResponse(asset.balanceOf(address));
  }

  async transfer(dto: CustodianTransferDto): Promise<ServiceResponse<CustodianTransferDto>> {
    const asset = this.asset();
    const address = await this.address();

    const approve = await fromPromiseToReceipt(asset.approve(address, dto.amount));
    if (approve.error) return approve;

    const transfer = await fromPromiseToReceipt(asset.transferFrom(address, dto.address, dto.amount));
    if (transfer.error) return transfer;

    return { data: dto };
  }

  private asset() {
    return MockStablecoin__factory.connect(this.usdcAddress, this.ethers.deployer());
  }

  private address(): Promise<string> {
    // TODO: for now custodian address and deployer address need to match
    return this.ethers.deployer().getAddress();
  }
}
