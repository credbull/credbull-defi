import { CredbullVaultFactory, CredbullVaultFactory__factory } from '@credbull/contracts';
import * as DeploymentData from '@credbull/contracts/deployments/index.json';
import { VaultDeployedEvent } from '@credbull/contracts/types/CredbullVaultFactory';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SupabaseClient } from '@supabase/supabase-js';
import * as _ from 'lodash';

import { EthersService } from '../../clients/ethers/ethers.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { ServiceResponse } from '../../types/responses';
import { Database, Tables } from '../../types/supabase';
import { responseFromRead } from '../../utils/contracts';

@Injectable()
export class SyncVaultsService {
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly ethers: EthersService,
    private readonly config: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async syncEventData() {
    console.log('Syncing vault data...');
    await this.sync();
  }

  private async sync() {
    this.supabaseAdmin = this.getSupabaseAdmin();

    const deleteCorrupted = await this.supabaseAdmin.from('vaults').delete().eq('status', 'created');
    if (deleteCorrupted.error) {
      console.log(deleteCorrupted.error);
      return;
    }

    const vaults = await this.supabaseAdmin.from('vaults').select();
    if (vaults.error) {
      console.log(vaults.error);
      return;
    }

    const chainId = `${await this.ethers.networkId()}` as keyof typeof DeploymentData;
    const factoryContract = this.getFactoryContract(DeploymentData[chainId].CredbullVaultFactory[0].address);
    const eventFilter = factoryContract.filters.VaultDeployed();
    const events = await responseFromRead(factoryContract.queryFilter(eventFilter));
    if (events.error) {
      console.log(events.error);
      return;
    }

    //Add all past events if any
    if (events.data.length > 0) {
      const vaultsInDB = vaults.data.map((vault) => vault.address);
      const vaultsToBeAdded = events.data.filter((event) => !vaultsInDB.includes(event.args.vault));

      const processedEvents = await this.processEventData(vaultsToBeAdded);
      if (processedEvents.error) {
        console.log(processedEvents.error);
      }
      return;
    }

    //Remove duplicates
    if (vaults.data.length > events.data.length) {
      const vaultAddresses = vaults.data.map((vault) => vault.address);
      const duplicates = _.uniq(_.filter(vaultAddresses, (v, i) => vaultAddresses.indexOf(v) !== i));

      const deleted = await this.supabaseAdmin.from('vaults').delete().in('address', duplicates);
      if (deleted.error) {
        console.log(deleted.error);
      }
      return;
    }
  }

  private getSupabaseAdmin() {
    return SupabaseService.createAdmin(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
    );
  }

  private getFactoryContract(addr: string): CredbullVaultFactory {
    return CredbullVaultFactory__factory.connect(addr, this.ethers.deployer());
  }

  private prepareVaultDataFromEvent(event: VaultDeployedEvent) {
    return {
      type: 'fixed_yield' as const,
      status: 'created' as const,
      opened_at: new Date(Number(event.args.params.depositOpensAt) * 1000).toISOString(),
      closed_at: new Date(Number(event.args.params.depositClosesAt) * 1000).toISOString(),
      address: event.args.vault,
      strategy_address: event.args.vault,
      asset_address: event.args.params.asset,
    };
  }

  private prepareEntitiesDataFromEvent(events: VaultDeployedEvent[], vaults: Tables<'vaults'>[]) {
    return events.flatMap((event, index) => {
      return [
        { vault_id: vaults[index].id, address: event.args.params.custodian, type: 'custodian' as const },
        { vault_id: vaults[index].id, address: event.args.params.kycProvider, type: 'kyc_provider' as const },
        { vault_id: vaults[index].id, address: event.args.params.treasury, type: 'treasury' as const },
        {
          vault_id: vaults[index].id,
          address: event.args.params.activityReward,
          type: 'activity_reward' as const,
        },
        { vault_id: vaults[index].id, address: event.args.vault, type: 'vault' as const },
      ];
    });
  }

  private prepareConfigDataFromEntities(entities: Tables<'vault_distribution_entities'>) {
    if (['custodian', 'kyc_provider'].includes(entities.type)) return [];

    const vault = { order: 0, percentage: 0.2 };
    const treasury = { order: 1, percentage: 0.8 };
    const activity_reward = { order: 2, percentage: 1 };

    const config = entities.type === 'vault' ? vault : entities.type === 'treasury' ? treasury : activity_reward;

    return [{ entity_id: entities.id, ...config }];
  }

  private async processEventData(events: VaultDeployedEvent[]): Promise<ServiceResponse<any>> {
    //Push vault
    const newVaults = await this.supabaseAdmin
      .from('vaults')
      .insert(events.map(this.prepareVaultDataFromEvent))
      .select();
    if (newVaults.error) return newVaults;
    if (!newVaults.data) return { error: new Error('No data') };

    //Push entities
    const entities = await this.supabaseAdmin
      .from('vault_distribution_entities')
      .insert(this.prepareEntitiesDataFromEvent(events, newVaults.data))
      .select();
    if (entities.error) return entities;
    if (!entities.data) return { error: new Error('No data') };

    //Push config
    const configs = await this.supabaseAdmin
      .from('vault_distribution_configs')
      .insert(entities.data.flatMap(this.prepareConfigDataFromEntities))
      .select();

    if (configs.error) return configs;
    if (!configs.data) return { error: new Error('No data') };

    const ids = newVaults.data.map((v) => v.id);
    return this.supabaseAdmin.from('vaults').update({ status: 'ready' }).in('id', ids).select();
  }
}
