import { CredbullFixedYieldVault, CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { BigNumber } from 'ethers';
import * as _ from 'lodash';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { ServiceResponse } from '../../types/responses';
import { Tables } from '../../types/supabase';
import { responseFromRead, responseFromWrite } from '../../utils/contracts';
import { CustodianAmountLesserThanExpected, anyCallHasFailed } from '../../utils/errors';

import { CustodianTransferDto } from './custodian.dto';
import { CustodianService } from './custodian.service';
import {
  CalculateProportionsData,
  DistributionConfig,
  calculateProportions,
  prepareDistributionTransfers,
} from './vaults.domain';
import { getUnpausedVaults } from './vaults.repository';

@Injectable()
export class MatureVaultsService {
  constructor(
    private readonly ethers: EthersService,
    private readonly custodian: CustodianService,
    private readonly supabaseAdmin: SupabaseAdminService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(this.constructor.name);
  }

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async matureVaults() {
    this.logger.log('Maturing vaults...');
    await this.matureOutstanding();
  }

  async matureOutstanding(): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const vaults = await this.supabaseAdmin
      .admin()
      .from('vaults')
      .select('*')
      .eq('status', 'ready')
      .lte('redemptions_opened_at', 'now()');

    if (vaults.error) return vaults;
    if (!vaults.data || vaults.data.length === 0) return { data: [] };

    const unPausedVaults = await getUnpausedVaults(vaults, await this.ethers.operator());

    // get all custodians and group vaults by custodian
    const custodians = await this.custodian.forVaults(unPausedVaults);
    if (custodians.error) return custodians;
    const groupedVaults = _.groupBy(custodians.data, 'address');

    // gather all data required to transfer assets from the custodian to the vaults
    const transfers = await Promise.all(
      _.values(_.mapValues(groupedVaults, (group, key) => this.prepareAllTransfers(unPausedVaults, group, key))),
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
    for (const vault of unPausedVaults) {
      const matured = await this.mature(vault);
      if (matured.error) errors.push(matured.error);
      if (matured.data) maturedVaults.push(...matured.data);
    }

    return errors.length > 0 ? { error: new AggregateError(errors) } : { data: maturedVaults };
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

  private async distributionConfig(vault: Tables<'vaults'>): Promise<ServiceResponse<DistributionConfig[]>> {
    return this.supabaseAdmin
      .admin()
      .from('vault_distribution_configs')
      .select('*, vault_entities!inner (type, address)')
      .eq('vault_entities.vault_id', vault.id)
      .order('order');
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
      return { error: CustodianAmountLesserThanExpected };
    }

    return { data: dtos };
  }

  private async requiredDataForVaults(vault: Tables<'vaults'>, custodianAddress: string) {
    const contract = await this.contract(vault);
    return [responseFromRead(contract.expectedAssetsOnMaturity()), this.custodian.totalAssets(vault, custodianAddress)];
  }

  private async mature(vault: Tables<'vaults'>): Promise<ServiceResponse<Tables<'vaults'>[]>> {
    const strategy = await this.strategy(vault);
    const maturedOnChain = await responseFromWrite(strategy.mature(this.ethers.overrides()));
    if (maturedOnChain.error) return maturedOnChain;

    return this.supabaseAdmin.admin().from('vaults').update({ status: 'matured' }).eq('id', vault.id).select();
  }

  private async contract(vault: Tables<'vaults'>): Promise<CredbullFixedYieldVault> {
    return CredbullFixedYieldVault__factory.connect(vault.address, await this.ethers.operator());
  }

  private async strategy(vault: Tables<'vaults'>): Promise<CredbullFixedYieldVault> {
    return CredbullFixedYieldVault__factory.connect(vault.strategy_address, await this.ethers.operator());
  }
}
