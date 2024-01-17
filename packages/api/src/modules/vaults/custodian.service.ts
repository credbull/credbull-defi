import { ERC20__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { BigNumber } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';

import { CustodianTransferDto } from './custodian.dto';

@Injectable()
export class CustodianService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
  ) {}

  async totalAssets(vault: Tables<'vaults'>, custodianAddress?: string): Promise<ServiceResponse<BigNumber>> {
    const asset = this.asset(vault);

    const address = custodianAddress ? { data: custodianAddress } : await this.address(vault);
    if (address.error) return address;

    return responseFromRead(asset.balanceOf(address.data));
  }

  async transfer(dto: CustodianTransferDto, custodianAddress?: string): Promise<ServiceResponse<CustodianTransferDto>> {
    const asset = this.asset(dto);

    const address = custodianAddress ? { data: custodianAddress } : await this.address({ id: dto.vault_id });
    if (address.error) return address;

    const approve = await responseFromWrite(asset.approve(address.data, dto.amount));
    if (approve.error) return approve;

    const transfer = await responseFromWrite(
      asset.transferFrom(address.data, dto.address, dto.amount, this.ethers.overrides()),
    );
    if (transfer.error) return transfer;

    return { data: dto };
  }

  async forVaults(vaults: Pick<Tables<'vaults'>, 'id'>[]) {
    const { error, data } = await this.supabase
      .admin()
      .from('vault_distribution_entities')
      .select('*, vaults (id)')
      .in(
        'vault_id',
        vaults.map((vault) => vault.id),
      )
      .eq('type', 'custodian');

    if (error) return { error };

    return { data };
  }

  private asset(vault: Pick<Tables<'vaults'>, 'asset_address'>) {
    return ERC20__factory.connect(vault.asset_address, this.ethers.custodian());
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
