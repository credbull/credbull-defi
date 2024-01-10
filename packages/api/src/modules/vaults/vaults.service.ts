import { Injectable } from '@nestjs/common';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';

import { DISTRIBUTION_CONFIG } from './vaults.dto';

@Injectable()
export class VaultsService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
  ) {}

  async current(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    return this.supabase
      .client()
      .from('vaults')
      .select('*')
      .eq('status', 'ready')
      .lt('opened_at', 'now()')
      .gt('closed_at', 'now()');
  }

  async matureOutstanding(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const { data } = await this.supabase
      .admin()
      .from('vaults')
      .select('*')
      .eq('status', 'ready')
      .lte('closed_at', 'now()');

    if (!data) return { data: [] };

    for (const vault of data) {
      // get final total assets from vault contract
      const totalAssets = 1000;
      // get final total returns from custodian (circle)
      let totalReturns = 1200;

      const splits = [];
      for (const { entity, percentage } of this.distributionConfig()) {
        const amount =
          entity === 'vault' //
            ? totalAssets * percentage
            : totalReturns * percentage;

        splits.push({ entity, amount });
        totalReturns -= amount;
      }

      // distribute returns
      // api call with idempotency key to circle

      // set vault as matured in the blockchain and Supabase
      await Promise.all([
        this.supabase.admin().from('vaults').update({ status: 'created' }).eq('id', vault.id),
        this.ethers.deployer().sendTransaction({}),
      ]);
    }

    return { data };
  }

  private distributionConfig() {
    return DISTRIBUTION_CONFIG;
  }
}
