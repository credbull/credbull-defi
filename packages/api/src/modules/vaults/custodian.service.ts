import { abis, deployments } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { Contract } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';

import { CustodianTransferDto } from './custodian.dto';

@Injectable()
export class CustodianService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
  ) {}

  async totalAssets(): Promise<ServiceResponse<number>> {
    const coin = this.mockStablecoin();
    const address = await this.ethers.deployer().getAddress();

    const data = await coin.balanceOf(address);
    return { data };
  }

  async transfer(dto: CustodianTransferDto): Promise<ServiceResponse<CustodianTransferDto>> {
    const coin = this.mockStablecoin();

    try {
      const address = await this.ethers.deployer().getAddress();

      await coin.approve(address, dto.amount);
      await coin.transferFrom(address, dto.address, dto.amount);
      return { data: dto };
    } catch (error) {
      return { error };
    }
  }

  private mockStablecoin(): Contract {
    return new Contract(deployments.local.MockStablecoin.address, abis.MockStablecoin.abi, this.ethers.deployer());
  }
}
