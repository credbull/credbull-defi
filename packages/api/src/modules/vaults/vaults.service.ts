import { CredbullVault__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { BigNumber } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';
import { anyCallHasFailed } from '../../utils/errors';

import { CustodianService } from './custodian.service';

@Injectable()
export class VaultsService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly custodian: CustodianService,
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
    const vaults = await this.supabase
      .admin()
      .from('vaults')
      .select('*')
      .eq('status', 'ready')
      .lte('closed_at', 'now()');

    if (vaults.error) return vaults;
    if (!vaults.data) return { data: [] };

    const errors = [];
    for (const vault of vaults.data) {
      const assets = await Promise.all([
        this.expectedAssetsOnMaturity(vault),
        this.custodian.totalAssets(),
        this.distributionConfig(vault),
      ]);
      for (const call of assets) if ('error' in call) errors.push(call.error);
      if (anyCallHasFailed(assets)) continue;

      const [{ data: expectedAssetsOnMaturity }, { data: custodianTotalAssets }, { data: distributionConfig }] = assets;

      const transfers = await this.transferDistribution(
        vault,
        expectedAssetsOnMaturity!,
        custodianTotalAssets!,
        distributionConfig!,
      );
      for (const call of transfers) if ('error' in call) errors.push(call.error);
      if (anyCallHasFailed(transfers)) continue;

      const maturing = await Promise.all([
        this.supabase.admin().from('vaults').update({ status: 'matured' }).eq('id', vault.id),
        responseFromWrite(this.vaultContract(vault).mature()),
      ]);
      for (const call of maturing) if ('error' in call) errors.push(call.error);
    }

    return errors.length > 0 ? { error: new AggregateError(errors) } : vaults;
  }

  async expectedAssetsOnMaturity(vault: Tables<'vaults'>): Promise<ServiceResponse<BigNumber>> {
    return responseFromRead(this.vaultContract(vault).expectedAssetsOnMaturity());
  }

  private vaultContract(vault: Tables<'vaults'>) {
    return CredbullVault__factory.connect(vault.address, this.ethers.deployer());
  }

  private async transferDistribution(
    vault: Tables<'vaults'>,
    expectedAssetsOnMaturity: BigNumber,
    custodianTotalAssets: BigNumber,
    distributionConfig: NonNullable<Awaited<ReturnType<typeof this.distributionConfig>>['data']>,
  ) {
    const splits = this.calculateDistribution(
      vault,
      expectedAssetsOnMaturity,
      custodianTotalAssets,
      distributionConfig,
    );

    return Promise.all(splits.map(async (split) => this.custodian.transfer(split)));
  }

  private calculateDistribution(
    vault: Tables<'vaults'>,
    expectedAssetsOnMaturity: BigNumber,
    custodianTotalAssets: BigNumber,
    distributionConfig: NonNullable<Awaited<ReturnType<typeof this.distributionConfig>>['data']>,
  ) {
    let totalReturns = custodianTotalAssets.sub(expectedAssetsOnMaturity);
    const splits = [{ address: vault.address, amount: expectedAssetsOnMaturity }];

    for (const { vault_distribution_entities, percentage } of distributionConfig) {
      const amount = totalReturns.mul(percentage);

      splits.push({ address: vault_distribution_entities!.address, amount });
      totalReturns = totalReturns.sub(amount);
    }

    return splits;
  }

  private async distributionConfig(vault: Tables<'vaults'>) {
    return this.supabase
      .admin()
      .from('vault_distribution_configs')
      .select('*, vault_distribution_entities (type, address)')
      .eq('vault_id', vault.id)
      .order('order');
  }
}
