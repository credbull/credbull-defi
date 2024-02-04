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

  async totalAssets(vault: Tables<'vaults'>, custodianAddress: string): Promise<ServiceResponse<BigNumber>> {
    const asset = this.asset(vault);
    return responseFromRead(asset.balanceOf(custodianAddress));
  }

  async transfer(dto: CustodianTransferDto): Promise<ServiceResponse<CustodianTransferDto>> {
    const asset = this.asset(dto);

    const approve = await responseFromWrite(asset.approve(dto.custodian_address, dto.amount));
    if (approve.error) return approve;

    const transfer = await responseFromWrite(
      asset.transferFrom(dto.custodian_address, dto.address, dto.amount, this.ethers.overrides()),
    );
    if (transfer.error) return transfer;

    return { data: dto };
  }

  async forVaults(vaults: Pick<Tables<'vaults'>, 'id'>[]) {
    return this.supabase
      .admin()
      .from('vault_entities')
      .select('*, vaults (id)')
      .in(
        'vault_id',
        vaults.map((vault) => vault.id),
      )
      .eq('type', 'custodian');
  }

  private asset(vault: Pick<Tables<'vaults'>, 'asset_address'>) {
    return ERC20__factory.connect(vault.asset_address, this.ethers.custodian());
  }
}
