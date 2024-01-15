import { CredbullVault, CredbullVault__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { BigNumber } from 'ethers';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Enums, Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';
import { anyCallHasFailed } from '../../utils/errors';

import { CustodianTransferDto } from './custodian.dto';
import { CustodianService } from './custodian.service';

type DistributionConfig = Tables<'vault_distribution_configs'> & {
  vault_distribution_entities: Pick<Tables<'vault_distribution_entities'>, 'type' | 'address'> | null;
};

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
      const contract = this.contract(vault);

      // gather all the data we need to calculate the asset distribution
      const assets = await Promise.all([
        this.expectedAssetsOnMaturity(contract),
        this.custodian.totalAssets(vault),
        this.distributionConfig(vault),
      ]);
      for (const call of assets) if (call.error) errors.push(call.error);
      if (anyCallHasFailed(assets)) continue;

      const [{ data: expectedAssetsOnMaturity }, { data: custodianTotalAssets }, { data: distributionConfig }] = assets;

      // calculate the distribution and transfer the assets
      const transfers = await this.transferDistribution(
        vault,
        expectedAssetsOnMaturity!,
        custodianTotalAssets!,
        distributionConfig!,
      );
      for (const call of transfers) if (call.error) errors.push(call.error);
      if (anyCallHasFailed(transfers)) continue;

      // mature the vault on and off chain
      const matured = await this.mature(vault, contract);
      if (matured.error) errors.push(matured.error);
    }

    const maturedVaults = vaults.data.map((v) => ({ ...v, status: 'matured' as Enums<'vault_status'> }));
    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: maturedVaults };
  }

  private async expectedAssetsOnMaturity(contract: CredbullVault): Promise<ServiceResponse<BigNumber>> {
    return responseFromRead(contract.expectedAssetsOnMaturity());
  }

  private async distributionConfig(vault: Tables<'vaults'>): Promise<ServiceResponse<DistributionConfig[]>> {
    return this.supabase
      .admin()
      .from('vault_distribution_configs')
      .select('*, vault_distribution_entities!inner (type, address)')
      .eq('vault_distribution_entities.vault_id', vault.id)
      .order('order');
  }

  private async transferDistribution(
    vault: Tables<'vaults'>,
    expectedAssetsOnMaturity: BigNumber,
    custodianTotalAssets: BigNumber,
    distributionConfig: DistributionConfig[],
  ): Promise<ServiceResponse<CustodianTransferDto>[]> {
    const { error, data: splits } = this.calculateDistribution(
      vault,
      expectedAssetsOnMaturity,
      custodianTotalAssets,
      distributionConfig,
    );

    if (error) return [{ error }];

    const calls: ServiceResponse<CustodianTransferDto>[] = [];
    for (const split of splits!) {
      const call = await this.custodian.transfer({ ...split, vaultId: vault.id });
      calls.push(call);
    }

    return calls;
  }

  private calculateDistribution(
    vault: Tables<'vaults'>,
    expectedAssetsOnMaturity: BigNumber,
    custodianTotalAssets: BigNumber,
    distributionConfig: DistributionConfig[],
  ): ServiceResponse<{ address: string; amount: BigNumber }[]> {
    try {
      let totalReturns = custodianTotalAssets.sub(expectedAssetsOnMaturity);
      const splits = [{ address: vault.address, amount: expectedAssetsOnMaturity }];

      for (const { vault_distribution_entities, percentage } of distributionConfig) {
        const amount = totalReturns.mul(percentage * 100).div(100);

        splits.push({ address: vault_distribution_entities!.address, amount });
        totalReturns = totalReturns.sub(amount);
      }
      return { data: splits };
    } catch (e) {
      return { error: e };
    }
  }

  private async mature(vault: Tables<'vaults'>, contract: CredbullVault) {
    const maturedOnChain = await responseFromWrite(contract.mature(this.ethers.overrides()));
    if (maturedOnChain.error) return maturedOnChain;

    return this.supabase.admin().from('vaults').update({ status: 'matured' }).eq('id', vault.id);
  }

  private contract(vault: Tables<'vaults'>): CredbullVault {
    return CredbullVault__factory.connect(vault.address, this.ethers.deployer());
  }
}
