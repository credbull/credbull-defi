import {
  CredbullFixedYieldVaultFactory,
  CredbullFixedYieldVaultFactory__factory,
  CredbullUpsideVaultFactory,
  CredbullUpsideVaultFactory__factory,
  FixedYieldVault,
  FixedYieldVault__factory,
} from '@credbull/contracts';
import { VaultDeployedEvent } from '@credbull/contracts/types/CredbullFixedYieldVaultFactory';
import { VaultDeployedEvent as UpsideVaultDeployedEvent } from '@credbull/contracts/types/CredbullUpsideVaultFactory';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { ServiceResponse } from '../../types/responses';
import { Database, Tables } from '../../types/supabase';
import { NoDataFound } from '../../utils/errors';
import { TomlConfigService } from '../../utils/tomlConfig';

import { VaultParamsDto } from './vaults.dto';
import {
  addEntitiesAndDistribution,
  getFactoryContractAddress,
  getFactoryUpsideContractAddress,
} from './vaults.repository';

@Injectable()
export class SyncVaultsService {
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly tomlConfigService: TomlConfigService,
    private readonly ethers: EthersService,
    private readonly supabase: SupabaseAdminService,
    private readonly logger: ConsoleLogger,
  ) {
    this.logger.setContext(this.constructor.name);
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async syncEventData() {
    this.logger.log('Syncing vault data...');
    await this.sync();
  }

  private async sync() {
    this.supabaseAdmin = this.supabase.admin();

    const deleteCorrupted = await this.supabaseAdmin.from('vaults').delete().eq('status', 'created');
    if (deleteCorrupted.error) {
      this.logger.error(deleteCorrupted.error);
      return;
    }

    const chainId = await this.ethers.networkId();
    await this.processEvents(chainId.toString(), false);
    await this.processEvents(chainId.toString(), true);
  }

  private async processEvents(chainId: string, upside: boolean) {
    const factoryAddress = upside
      ? await getFactoryUpsideContractAddress(chainId, this.supabaseAdmin)
      : await getFactoryContractAddress(chainId, this.supabaseAdmin);

    if (factoryAddress.error || !factoryAddress.data) {
      this.logger.error(factoryAddress.error || 'No factory address');
      return;
    }

    const upsideFactoryContract = await this.getFactoryUpsideContract(factoryAddress.data.address);
    const factoryContract = await this.getFactoryContract(factoryAddress.data.address);

    const eventFilter = upside
      ? upsideFactoryContract.filters.VaultDeployed()
      : factoryContract.filters.VaultDeployed();

    const events = await this.fetchLogsFromLastBlocks(upside ? upsideFactoryContract : factoryContract, eventFilter);

    //Add all past events if any
    if (events.length > 0) {
      const vaults = await this.supabaseAdmin.from('vaults').select('address');

      if (vaults.error) {
        this.logger.error(vaults.error);
        return;
      }

      const vaultsInDB = vaults.data.map((vault) => vault.address);

      const vaultsToBeAdded = events
        .filter((event) => !vaultsInDB.includes(event.args.vault))
        .filter(async (v) => {
          const contract = await this.getVaultContract(v.address);
          return !(await contract.paused());
        });

      const processedEvents = await this.processEventData(vaultsToBeAdded, upside);
      if (processedEvents.error) this.logger.error(processedEvents.error);
    }
  }

  private async fetchLogsFromLastBlocks(contract: any, eventFilter: any): Promise<VaultDeployedEvent[]> {
    const latestBlock = await this.ethers.getBlockNumber();

    const blockHistory: number = this.tomlConfigService.config.services.sync_vaults.block_history;

    const fromBlock = latestBlock - blockHistory;

    try {
      const logs = await contract.queryFilter(eventFilter, fromBlock, latestBlock);
      return logs;
    } catch (error) {
      this.logger.error(`Error fetching logs from ${fromBlock} to ${latestBlock}:`, error);
      throw error;
    }
  }

  private async processEventData(
    events: VaultDeployedEvent[] | UpsideVaultDeployedEvent[],
    upside: boolean,
  ): Promise<ServiceResponse<any>> {
    //Push vault
    const newVaults = await this.supabaseAdmin
      .from('vaults')
      .insert(events.map((e) => this.prepareVaultDataFromEvent(e, upside)))
      .select();
    if (newVaults.error) return newVaults;
    if (!newVaults.data) return { error: NoDataFound };

    const entities = await Promise.all(this.addEntitiesAndDistributionFromEvents(events, newVaults.data));
    const errors = entities.map((entity) => entity.error).filter((error) => error !== undefined);
    if (errors.length > 0) return { error: new AggregateError(errors) };

    const ids = newVaults.data.map((v) => v.id);
    return this.supabaseAdmin.from('vaults').update({ status: 'ready' }).in('id', ids).select();
  }

  private prepareVaultDataFromEvent(event: VaultDeployedEvent | UpsideVaultDeployedEvent, upside: boolean) {
    const { tenant } = JSON.parse(event.args.options) as Pick<VaultParamsDto, 'entities' | 'tenant'>;

    if (upside) {
      const params = event.args.params as UpsideVaultDeployedEvent['args']['params'];
      return {
        type: 'fixed_yield_upside',
        status: 'created' as const,
        deposits_opened_at: new Date(
          Number(params.fixedYieldVaultParams.windowVaultParams.depositWindow.opensAt) * 1000,
        ).toISOString(),
        deposits_closed_at: new Date(
          Number(params.fixedYieldVaultParams.windowVaultParams.depositWindow.closesAt) * 1000,
        ).toISOString(),
        redemptions_opened_at: new Date(
          Number(params.fixedYieldVaultParams.windowVaultParams.matureWindow.opensAt) * 1000,
        ).toISOString(),
        redemptions_closed_at: new Date(
          Number(params.fixedYieldVaultParams.windowVaultParams.matureWindow.opensAt) * 1000,
        ).toISOString(),
        address: event.args.vault,
        strategy_address: event.args.vault,
        asset_address: params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.asset,
        tenant,
      } as Tables<'vaults'>;
    }

    const params = event.args.params as VaultDeployedEvent['args']['params'];
    return {
      type: 'fixed_yield',
      status: 'created' as const,
      deposits_opened_at: new Date(Number(params.windowVaultParams.depositWindow.opensAt) * 1000).toISOString(),
      deposits_closed_at: new Date(Number(params.windowVaultParams.depositWindow.closesAt) * 1000).toISOString(),
      redemptions_opened_at: new Date(Number(params.windowVaultParams.matureWindow.opensAt) * 1000).toISOString(),
      redemptions_closed_at: new Date(Number(params.windowVaultParams.matureWindow.opensAt) * 1000).toISOString(),
      address: event.args.vault,
      strategy_address: event.args.vault,
      asset_address: params.maturityVaultParams.baseVaultParams.asset,
      tenant,
    } as Tables<'vaults'>;
  }

  private addEntitiesAndDistributionFromEvents(
    events: VaultDeployedEvent[] | UpsideVaultDeployedEvent[],
    vaults: Tables<'vaults'>[],
  ) {
    return events.flatMap((event, index) => {
      const { entities } = JSON.parse(event.args.options) as Pick<VaultParamsDto, 'entities' | 'tenant'>;
      return addEntitiesAndDistribution(entities, vaults[index], this.supabaseAdmin);
    });
  }

  private async getVaultContract(addr: string): Promise<FixedYieldVault> {
    return FixedYieldVault__factory.connect(addr, await this.ethers.operator());
  }

  private async getFactoryContract(addr: string): Promise<CredbullFixedYieldVaultFactory> {
    return CredbullFixedYieldVaultFactory__factory.connect(addr, await this.ethers.operator());
  }

  private async getFactoryUpsideContract(addr: string): Promise<CredbullUpsideVaultFactory> {
    return CredbullUpsideVaultFactory__factory.connect(addr, await this.ethers.operator());
  }
}
