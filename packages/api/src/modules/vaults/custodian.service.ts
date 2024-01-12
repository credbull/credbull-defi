import { abis, deployments } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { Contract } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse, fromPromiseToReceipt, fromPromiseToResponse } from '../../types/responses';

import { CustodianTransferDto } from './custodian.dto';

@Injectable()
export class CustodianService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
  ) {}

  async totalAssets(): Promise<ServiceResponse<number>> {
    const asset = this.asset();
    const address = await this.address();

    return fromPromiseToResponse(asset.balanceOf(address));
  }

  async transfer(dto: CustodianTransferDto): Promise<ServiceResponse<CustodianTransferDto>> {
    const asset = this.asset();
    const address = await this.address();

    const approve = await fromPromiseToReceipt(await asset.approve(address, dto.amount));
    if (approve.error) return approve;

    const transfer = await fromPromiseToReceipt(await asset.transferFrom(address, dto.address, dto.amount));
    if (transfer.error) return transfer;

    return { data: dto };
  }

  private asset(): Contract {
    return new Contract(deployments.local.MockStablecoin.address, abis.MockStablecoin.abi, this.ethers.deployer());
  }

  private address(): Promise<string> {
    // TODO: for now custodian address and deployer address need to match
    return this.ethers.deployer().getAddress();
  }
}
