import { CredbullVault, CredbullVault__factory } from '@credbull/contracts';
import { Injectable } from '@nestjs/common';
import { BigNumber } from 'ethers';
import * as _ from 'lodash';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';
import { anyCallHasFailed } from '../../utils/errors';

import { CustodianTransferDto } from './custodian.dto';
import { CustodianService } from './custodian.service';
import { DistributionConfig, calculateDistribution } from './vaults.domain';

@Injectable()
export class VaultsService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly custodian: CustodianService,
  ) {}

  async current(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    return this.supabase.client().from('vaults').select('*').neq('status', 'created').lt('opened_at', 'now()');
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

    const custodians = await this.custodian.forVaults(vaults.data);
    if (custodians.error) return custodians;

    const groupedVaults = _.groupBy(custodians.data, 'address');
    const matured = await Promise.all(
      _.values(_.mapValues(groupedVaults, (group, key) => this.maturedVaults(vaults.data, group, key))),
    );

    if (anyCallHasFailed(matured)) return { error: new AggregateError(_.compact(matured.map((m) => m.error))) };
    return { data: _.compact(matured.flatMap((m) => m.data)) };
  }

  private async maturedVaults(
    vaults: Tables<'vaults'>[],
    group: NonNullable<Awaited<ReturnType<typeof this.custodian.forVaults>>['data']>,
    custodianAddress: string,
  ): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const vaultIds = group.map((custodian) => custodian.vaults?.id);
    const vaultsForCustodian = vaults.filter((vault) => vaultIds.includes(vault.id));

    const transfer = await this.transferToVaults(vaultsForCustodian, custodianAddress);
    if (transfer.error) return transfer;

    const errors: ServiceResponse<any>['error'][] = [];
    const maturedVaults: Tables<'vaults'>[] = [];
    for (let i = 0; i < vaultsForCustodian.length; i++) {
      const vault = vaultsForCustodian[i];

      // gather all the data we need to calculate the asset distribution
      const requiredData = await Promise.all(this.requiredDataForEntities(vault, custodianAddress));
      for (const call of requiredData) if (call.error) errors.push(call.error);
      if (anyCallHasFailed(requiredData)) continue;

      const [{ data: custodianTotalAssets }, { data: distributionConfig }] = requiredData;

      // calculate the distribution and transfer the assets
      const transfers = await this.transferDistribution(
        vaultsForCustodian.length - i,
        vault,
        custodianTotalAssets!,
        distributionConfig!,
      );
      for (const call of transfers) if (call.error) errors.push(call.error);
      if (anyCallHasFailed(transfers)) continue;

      // mature the vault on and off chain
      const matured = await this.mature(vault);
      if (matured.error) errors.push(matured.error);
      if (matured.data) maturedVaults.push(...matured.data);
    }

    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: maturedVaults };
  }

  private async transferToVaults(vaults: Tables<'vaults'>[], custodianAddress: string) {
    const errors = [];
    for (const vault of vaults) {
      const requiredData = await Promise.all(this.requiredDataForVaults(vault, custodianAddress));
      for (const call of requiredData) if (call.error) errors.push(call.error);
      if (anyCallHasFailed(requiredData)) continue;

      const [{ data: expectedAssetsOnMaturity }, { data: custodianTotalAssets }] = requiredData;

      if (custodianTotalAssets!.lt(expectedAssetsOnMaturity!))
        return { error: new Error('Custodian amount should be bigger or same as expected amount') };

      const dto = { ...vault, vault_id: vault.id, amount: expectedAssetsOnMaturity! };
      const transfer = await this.custodian.transfer(dto);
      if (transfer.error) errors.push(transfer.error);
    }
    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: vaults };
  }

  private requiredDataForVaults(vault: Tables<'vaults'>, custodianAddress: string) {
    return [this.expectedAssetsOnMaturity(vault), this.custodian.totalAssets(vault, custodianAddress)];
  }

  private requiredDataForEntities(
    vault: Tables<'vaults'>,
    custodianAddress: string,
  ): [Promise<ServiceResponse<BigNumber>>, Promise<ServiceResponse<DistributionConfig[]>>] {
    return [this.custodian.totalAssets(vault, custodianAddress), this.distributionConfig(vault)];
  }

  private async expectedAssetsOnMaturity(vault: Tables<'vaults'>): Promise<ServiceResponse<BigNumber>> {
    const contract = this.contract(vault);
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
    parts: number,
    vault: Tables<'vaults'>,
    custodianTotalAssets: BigNumber,
    distributionConfig: DistributionConfig[],
  ): Promise<ServiceResponse<CustodianTransferDto>[]> {
    const { error, data: splits } = calculateDistribution(custodianTotalAssets, distributionConfig, parts);

    if (error) return [{ error }];

    const calls: ServiceResponse<CustodianTransferDto>[] = [];
    for (const split of splits!) {
      const dto = { asset_address: vault.asset_address, vault_id: vault.id, ...split };
      const call = await this.custodian.transfer(dto);
      calls.push(call);
    }

    return calls;
  }

  private async mature(vault: Tables<'vaults'>): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const strategy = this.strategy(vault);

    const maturedOnChain = await responseFromWrite(strategy.mature(this.ethers.overrides()));
    if (maturedOnChain.error) return maturedOnChain;

    return this.supabase.admin().from('vaults').update({ status: 'matured' }).eq('id', vault.id).select();
  }

  private contract(vault: Tables<'vaults'>): CredbullVault {
    return CredbullVault__factory.connect(vault.address, this.ethers.deployer());
  }

  private strategy(vault: Tables<'vaults'>): CredbullVault {
    return CredbullVault__factory.connect(vault.strategy_address, this.ethers.deployer());
  }
}
