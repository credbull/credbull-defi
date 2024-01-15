import { MockStablecoin__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BigNumber } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';

import { CustodianTransferDto } from './custodian.dto';

@Injectable()
export class CustodianService {
  private readonly usdcAddress: string;

  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly config: ConfigService,
  ) {
    this.usdcAddress = this.config.getOrThrow('USDC_CONTRACT_ADDRESS');
  }

  async totalAssets(vault: Tables<'vaults'>): Promise<ServiceResponse<BigNumber>> {
    const asset = this.asset();
    const address = await this.address(vault);
    if (address.error) return address;

    return responseFromRead(asset.balanceOf(address.data));
  }

  async transfer(dto: CustodianTransferDto): Promise<ServiceResponse<CustodianTransferDto>> {
    const asset = this.asset();

    const address = await this.address({ id: dto.vaultId });
    if (address.error) return address;

    const approve = await responseFromWrite(asset.approve(address.data, dto.amount));
    if (approve.error) return approve;

    const transfer = await responseFromWrite(
      asset.transferFrom(address.data, dto.address, dto.amount, this.ethers.overrides()),
    );
    if (transfer.error) return transfer;

    return { data: dto };
  }

  private asset() {
    return MockStablecoin__factory.connect(this.usdcAddress, this.ethers.custodian());
  }

  private async address(vault: Pick<Tables<'vaults'>, 'id'>): Promise<ServiceResponse<string>> {
    const { error, data } = await this.supabase
      .admin()
      .from('vault_distribution_entities')
      .select('address')
      .eq('vault_id', vault.id)
      .eq('type', 'custodian')
      .single();

    if (error) return { error };

    return { data: data.address };
  }
}
