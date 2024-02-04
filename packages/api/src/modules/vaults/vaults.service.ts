import {
  CredbullVault,
  CredbullVaultFactory,
  CredbullVaultFactory__factory,
  CredbullVault__factory,
} from '@credbull/contracts';
import { Injectable, NotFoundException } from '@nestjs/common';
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
import {
  CalculateProportionsData,
  DistributionConfig,
  calculateProportions,
  prepareDistributionTransfers,
} from './vaults.domain';
import { VaultParamsDto } from './vaults.dto';
import { addEntitiesAndDistribution, getFactoryContractAddress } from './vaults.repository';

@Injectable()
export class VaultsService {
  constructor(
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseService,
    private readonly custodian: CustodianService,
  ) {}

  async current(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    return this.supabase.client().from('vaults').select('*').neq('status', 'created').lt('deposits_opened_at', 'now()');
  }

  async createVault(params: VaultParamsDto): Promise<ServiceResponse<Tables<'vaults'>>> {
    const chainId = await this.ethers.networkId();
    const factoryAddress = await getFactoryContractAddress(chainId.toString(), this.supabase.admin());
    if (factoryAddress.error) return factoryAddress;
    if (!factoryAddress.data) return { error: new NotFoundException() };

    const factory = await this.factoryContract(factoryAddress.data.address);

    const options = JSON.stringify({ entities: params.entities });
    const estimation = await responseFromRead(factory.estimateGas.createVault(params, options));
    if (estimation.error) return estimation;

    const response = await responseFromWrite(factory.createVault(params, options, { gasLimit: estimation.data }));
    if (response.error) return response;

    const vaultAddress = response.data.events?.[2].args?.[0];
    const createdVault = await this.createVaultInDB(params, vaultAddress);
    if (createdVault.error) return createdVault;

    const entities = await addEntitiesAndDistribution(params.entities, createdVault.data, this.supabase.admin());
    if (entities.error) return entities;

    return await this.readyVaultInDB(createdVault.data);
  }

  async matureOutstanding(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const vaults = await this.supabase
      .admin()
      .from('vaults')
      .select('*')
      .eq('status', 'ready')
      .lte('redemptions_opened_at', 'now()');

    if (vaults.error) return vaults;
    if (!vaults.data || vaults.data.length === 0) return { data: [] };

    // get all custodians and group vaults by custodian
    const custodians = await this.custodian.forVaults(vaults.data);
    if (custodians.error) return custodians;
    const groupedVaults = _.groupBy(custodians.data, 'address');

    // gather all data required to transfer assets from the custodian to the vaults
    const transfers = await Promise.all(
      _.values(_.mapValues(groupedVaults, (group, key) => this.prepareAllTransfers(vaults.data, group, key))),
    );
    if (anyCallHasFailed(transfers)) return { error: new AggregateError(_.compact(transfers.map((m) => m.error))) };

    // transfer the assets from the custodian to the vaults sequentially so that we don't trigger any nonce errors
    const errors = [];
    for (const dto of transfers.flatMap((m) => m.data)) {
      const transfer = await this.custodian.transfer(dto!);
      if (transfer.error) errors.push(transfer.error);
    }

    // mature the vault on and off chain
    const maturedVaults = [];
    for (const vault of vaults.data) {
      const matured = await this.mature(vault);
      if (matured.error) errors.push(matured.error);
      if (matured.data) maturedVaults.push(...matured.data);
    }

    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: maturedVaults };
  }

  private async createVaultInDB(params: VaultParamsDto, vaultAddress: string) {
    const vaultData = {
      type: 'fixed_yield' as const,
      status: 'created' as const,
      deposits_opened_at: new Date(Number(params.depositOpensAt) * 1000).toISOString(),
      deposits_closed_at: new Date(Number(params.depositClosesAt) * 1000).toISOString(),
      redemptions_opened_at: new Date(Number(params.redemptionOpensAt) * 1000).toISOString(),
      redemptions_closed_at: new Date(Number(params.redemptionClosesAt) * 1000).toISOString(),
      address: vaultAddress,
      strategy_address: vaultAddress,
      asset_address: params.asset,
      tenant: params.tenant,
    } as Tables<'vaults'>;

    return this.supabase.admin().from('vaults').insert(vaultData).select().single();
  }

  private async readyVaultInDB(vault: Pick<Tables<'vaults'>, 'id'>) {
    return this.supabase.admin().from('vaults').update({ status: 'ready' }).eq('id', vault.id).select().single();
  }

  private async prepareAllTransfers(
    vaults: Tables<'vaults'>[],
    group: NonNullable<Awaited<ReturnType<typeof this.custodian.forVaults>>['data']>,
    custodianAddress: string,
  ): Promise<ServiceResponse<CustodianTransferDto[]>> {
    const dtos: CustodianTransferDto[] = [];

    const vaultIds = group.map((custodian) => custodian.vaults?.id);
    const vaultsForCustodian = vaults.filter((vault) => vaultIds.includes(vault.id));

    // transfer all assets from a single custodian to all related vaults
    const vaultTransfers = await this.prepareVaultTransfers(vaultsForCustodian, custodianAddress);
    if (vaultTransfers.error) return vaultTransfers;
    dtos.push(...vaultTransfers.data);

    // calculate the proportions for each vault so that we can distribute the assets to the entities
    const custodianProportions = calculateProportions(vaultTransfers.data);

    const errors: ServiceResponse<any>['error'][] = [];
    for (let i = 0; i < vaultsForCustodian.length; i++) {
      const vault = vaultsForCustodian[i];

      // gather all the data we need to calculate the asset distribution
      const distributionConfig = await this.distributionConfig(vault);
      if (distributionConfig.error) {
        errors.push(distributionConfig.error);
        continue;
      }

      // calculate the distribution and transfer the assets given the proportions
      const distributionTransfers = prepareDistributionTransfers(
        vault,
        custodianProportions[i],
        custodianAddress,
        distributionConfig.data,
      );
      if (distributionTransfers.error) {
        errors.push(distributionTransfers.error);
        continue;
      }
      dtos.push(...distributionTransfers.data);
    }

    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: dtos };
  }

  private async prepareVaultTransfers(
    vaults: Tables<'vaults'>[],
    custodianAddress: string,
  ): Promise<ServiceResponse<(CustodianTransferDto & CalculateProportionsData)[]>> {
    const errors = [];
    const dtos = [];

    // create the transfer dto for each vault
    for (const vault of vaults) {
      const requiredData = await Promise.all(await this.requiredDataForVaults(vault, custodianAddress));
      for (const call of requiredData) if (call.error) errors.push(call.error);
      if (anyCallHasFailed(requiredData)) continue;

      const [{ data: expectedAssetsOnMaturity }, { data: custodianTotalAssets }] = requiredData;

      dtos.push({
        ...vault,
        vault_id: vault.id,
        amount: expectedAssetsOnMaturity!,
        custodianAmount: custodianTotalAssets!,
        custodian_address: custodianAddress,
      });
    }

    if (errors.length > 0) return { error: new AggregateError(errors) };

    // check if the custodian has enough assets to transfer to all vaults or stop the process to avoid custody of any funds
    const totalExpectedAssets = dtos.reduce((acc, cur) => acc.add(cur.amount), BigNumber.from(0));
    if (dtos[0].custodianAmount.lt(totalExpectedAssets)) {
      return { error: new Error('Custodian amount should be bigger or same as expected amount') };
    }

    return { data: dtos };
  }

  private async requiredDataForVaults(vault: Tables<'vaults'>, custodianAddress: string) {
    const contract = await this.contract(vault);
    return [responseFromRead(contract.expectedAssetsOnMaturity()), this.custodian.totalAssets(vault, custodianAddress)];
  }

  private async distributionConfig(vault: Tables<'vaults'>): Promise<ServiceResponse<DistributionConfig[]>> {
    return this.supabase
      .admin()
      .from('vault_distribution_configs')
      .select('*, vault_entities!inner (type, address)')
      .eq('vault_entities.vault_id', vault.id)
      .order('order');
  }

  private async mature(vault: Tables<'vaults'>): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const strategy = await this.strategy(vault);

    const maturedOnChain = await responseFromWrite(strategy.mature(this.ethers.overrides()));
    if (maturedOnChain.error) return maturedOnChain;

    return this.supabase.admin().from('vaults').update({ status: 'matured' }).eq('id', vault.id).select();
  }

  private async contract(vault: Tables<'vaults'>): Promise<CredbullVault> {
    return CredbullVault__factory.connect(vault.address, await this.ethers.deployer());
  }

  private async strategy(vault: Tables<'vaults'>): Promise<CredbullVault> {
    return CredbullVault__factory.connect(vault.strategy_address, await this.ethers.deployer());
  }

  private async factoryContract(addr: string): Promise<CredbullVaultFactory> {
    return CredbullVaultFactory__factory.connect(addr, await this.ethers.deployer());
  }
}
