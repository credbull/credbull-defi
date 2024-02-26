import {
  CredbullFixedYieldVaultFactory,
  CredbullFixedYieldVaultFactory__factory,
  CredbullUpsideVaultFactory,
  CredbullUpsideVaultFactory__factory,
} from '@credbull/contracts';
import { VaultDeployedEvent } from '@credbull/contracts/types/CredbullVaultFactory';
import { ConsoleLogger, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Database, Tables } from '../../types/supabase';
import { responseFromRead } from '../../utils/contracts';
import { NoDataFound } from '../../utils/errors';

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
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
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
    this.supabaseAdmin = this.getSupabaseAdmin();

    const deleteCorrupted = await this.supabaseAdmin.from('vaults').delete().eq('status', 'created');
    if (deleteCorrupted.error) {
      this.logger.error(deleteCorrupted.error);
      return;
    }

    const vaults = await this.supabaseAdmin.from('vaults').select();
    if (vaults.error) {
      this.logger.error(vaults.error);
      return;
    }

    const chainId = await this.ethers.networkId();
    await this.processEvents(vaults.data, chainId.toString(), false);
    await this.processEvents(vaults.data, chainId.toString(), true);
  }

  private async processEvents(vaults: Tables<'vaults'>[], chainId: string, upside: boolean) {
    const factoryAddress = upside
      ? await getFactoryUpsideContractAddress(chainId, this.supabaseAdmin)
      : await getFactoryContractAddress(chainId, this.supabaseAdmin);

    if (factoryAddress.error || !factoryAddress.data) {
      this.logger.error(factoryAddress.error || 'No factory address');
      return;
    }

    const upsideFactoryContract = await this.factoryUpsideContract(factoryAddress.data.address);
    const factoryContract = await this.getFactoryContract(factoryAddress.data.address);

    const eventFilter = upside
      ? upsideFactoryContract.filters.VaultDeployed()
      : factoryContract.filters.VaultDeployed();

    const events = await responseFromRead(factoryContract.queryFilter(eventFilter));
    if (events.error) {
      this.logger.error(events.error);
      return;
    }

    //Add all past events if any
    if (events.data.length > 0) {
      const vaultsInDB = vaults.map((vault) => vault.address);
      const vaultsToBeAdded = events.data.filter((event) => !vaultsInDB.includes(event.args.vault));

      const processedEvents = await this.processEventData(vaultsToBeAdded, upside);
      if (processedEvents.error) {
        this.logger.error(processedEvents.error);
      }
      return;
    }
  }

  private prepareVaultDataFromEvent(event: VaultDeployedEvent, upside: boolean) {
    const { tenant } = JSON.parse(event.args.options) as Pick<VaultParamsDto, 'entities' | 'tenant'>;
    return {
      type: upside ? 'fixed_yield_upside' : 'fixed_yield',
      status: 'created' as const,
      deposits_opened_at: new Date(Number(event.args.params.depositOpensAt) * 1000).toISOString(),
      deposits_closed_at: new Date(Number(event.args.params.depositClosesAt) * 1000).toISOString(),
      redemptions_opened_at: new Date(Number(event.args.params.redemptionOpensAt) * 1000).toISOString(),
      redemptions_closed_at: new Date(Number(event.args.params.redemptionClosesAt) * 1000).toISOString(),
      address: event.args.vault,
      strategy_address: event.args.vault,
      asset_address: event.args.params.asset,
      tenant,
    } as Tables<'vaults'>;
  }

  private addEntitiesAndDistributionFromEvents(events: VaultDeployedEvent[], vaults: Tables<'vaults'>[]) {
    return events.flatMap((event, index) => {
      const { entities } = JSON.parse(event.args.options) as Pick<VaultParamsDto, 'entities' | 'tenant'>;
      return addEntitiesAndDistribution(entities, vaults[index], this.supabaseAdmin);
    });
  }

  private async processEventData(events: VaultDeployedEvent[], upside: boolean): Promise<ServiceResponse<any>> {
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

  private getSupabaseAdmin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private async getFactoryContract(addr: string): Promise<CredbullFixedYieldVaultFactory> {
    return CredbullFixedYieldVaultFactory__factory.connect(addr, await this.ethers.operator());
  }

  private async factoryUpsideContract(addr: string): Promise<CredbullUpsideVaultFactory> {
    return CredbullUpsideVaultFactory__factory.connect(addr, await this.ethers.operator());
  }
}
